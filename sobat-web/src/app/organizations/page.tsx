'use client';

import { useEffect, useState } from 'react';
import DashboardLayout from '@/components/DashboardLayout';
import apiClient from '@/lib/api-client';
import OrganizationTree from './components/OrganizationTree';
import OrganizationForm from './components/OrganizationForm';

interface Organization {
    id: number;
    name: string;
    code: string;
    type: string;
    parent_id?: number | null;
    address?: string;
    phone?: string;
    email?: string;
    line_style?: string;
    description?: string;
}

export default function OrganizationPage() {
    const [organizations, setOrganizations] = useState<Organization[]>([]);
    const [loading, setLoading] = useState(true);
    const [showForm, setShowForm] = useState(false);
    const [editingOrg, setEditingOrg] = useState<Organization | null>(null);
    const [defaultParentId, setDefaultParentId] = useState<number | null>(null);
    const [targetChildId, setTargetChildId] = useState<number | null>(null);

    const [selectedOrg, setSelectedOrg] = useState<Organization | null>(null);

    useEffect(() => {
        fetchOrganizations();
    }, []);

    const fetchOrganizations = async () => {
        try {
            setLoading(true);
            const response = await apiClient.get('/organizations');
            setOrganizations(response.data);
        } catch (error) {
            console.error('Failed to fetch orgs:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleCreate = () => {
        setEditingOrg(null);
        setDefaultParentId(null);
        setTargetChildId(null);
        setShowForm(true);
    };

    const handleEdit = (org: Organization) => {
        setEditingOrg(org);
        setDefaultParentId(null);
        setTargetChildId(null);
        setShowForm(true);
    };

    const handleAddChild = (parentId: number) => {
        setEditingOrg(null);
        setDefaultParentId(parentId);
        setTargetChildId(null);
        setShowForm(true);
    };

    const handleAddSibling = (parentId: number | null | undefined) => {
        setEditingOrg(null);
        setDefaultParentId(parentId || null);
        setTargetChildId(null);
        setShowForm(true);
    };

    const handleAddParent = (child: Organization) => {
        setEditingOrg(null);
        // The new parent should be at the same level as the child currently is
        setDefaultParentId(child.parent_id || null);
        setTargetChildId(child.id);
        setShowForm(true);
    };

    const handleFormSuccess = async (newOrg?: Organization) => {
        if (targetChildId && newOrg) {
            try {
                // Link the child to the new parent
                await apiClient.put(`/organizations/${targetChildId}`, {
                    parent_id: newOrg.id
                });
            } catch (error) {
                console.error('Failed to link child to new parent', error);
                alert('Organization created, but failed to link as parent. Please move manually.');
            } finally {
                setTargetChildId(null);
            }
        }
        fetchOrganizations();
    };

    const handleDelete = async (id: number) => {
        if (!confirm('Are you sure? This will delete the organization and all its children.')) return;

        try {
            await apiClient.delete(`/organizations/${id}`);
            fetchOrganizations();
        } catch (error: any) {
            alert(error.response?.data?.message || 'Failed to delete');
        }
    };

    const handleSelect = (org: Organization) => {
        setSelectedOrg(org);
    };

    const handleReset = async () => {
        if (!confirm('WARNING: Ini akan MENGHAPUS SEMUA data organisasi. Apakah Anda yakin?')) return;

        try {
            setLoading(true);
            await apiClient.delete('/organizations/reset');
            fetchOrganizations();
        } catch (error: any) {
            console.error('Failed to reset:', error);
            alert('Failed to reset data');
        } finally {
            setLoading(false);
        }
    };

    return (
        <DashboardLayout>
            <div className="flex justify-between items-center p-8 pb-0 animate-fade-in-up">
                <div>
                    <h1 className="text-2xl font-bold text-[#462e37]">Organization Structure</h1>
                    <p className="text-gray-500 mt-1">Manage hierarchical company structure</p>
                </div>
                <div className="flex gap-3">
                    <button
                        onClick={handleReset}
                        className="px-4 py-2 bg-red-50 text-red-500 font-semibold rounded-xl hover:bg-red-100 transition-all flex items-center gap-2 border border-red-100"
                    >
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" /></svg>
                        Reset All
                    </button>
                    <button
                        onClick={handleCreate}
                        className="px-4 py-2 bg-[#462e37] text-white font-semibold rounded-xl hover:bg-[#2d1e24] shadow-lg shadow-[#462e37]/20 transition-all flex items-center gap-2"
                    >
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" /></svg>
                        New Organization
                    </button>
                </div>
            </div>

            <div className="p-8">
                {loading ? (
                    <div className="flex items-center justify-center py-12">
                        <div className="w-8 h-8 border-4 border-[#a9eae2] border-t-transparent rounded-full animate-spin"></div>
                    </div>
                ) : (
                    <>
                        {/* Organization Chart */}
                        <OrganizationTree
                            organizations={organizations}
                            onEdit={handleEdit}
                            onAddChild={handleAddChild}
                            onAddSibling={handleAddSibling}
                            onDelete={handleDelete}
                            onSelect={handleSelect}
                            onAddParent={handleAddParent}
                        />

                        {/* Job Description / Details Panel */}
                        <div className="mt-8 grid grid-cols-1 lg:grid-cols-3 gap-6 animate-fade-in-up" key={selectedOrg?.id || 'empty'}>
                            <div className="lg:col-span-3">
                                <div className="glass-card p-6 rounded-xl border border-gray-100 bg-white shadow-sm">
                                    <h3 className="text-xl font-bold text-[#462e37] mb-4 flex items-center gap-2">
                                        <svg className="w-5 h-5 text-[#729892]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" /></svg>
                                        Uraian Jabatan & Detail (Description)
                                    </h3>

                                    {selectedOrg ? (
                                        <div className="space-y-4">
                                            <div className="flex items-start justify-between">
                                                <div>
                                                    <h4 className="text-lg font-bold text-gray-900">{selectedOrg.name}</h4>
                                                    <p className="text-sm text-gray-500 font-mono mt-1">{selectedOrg.code}</p>
                                                    <span className="inline-block px-2 py-1 bg-gray-100 text-gray-600 text-xs rounded-full mt-2 uppercase font-bold">{selectedOrg.type}</span>
                                                </div>
                                                <button onClick={() => handleEdit(selectedOrg)} className="text-[#a9eae2] hover:text-[#729892] text-sm font-semibold">
                                                    Edit Details
                                                </button>
                                            </div>

                                            <hr className="border-gray-100" />

                                            <div>
                                                <h5 className="text-sm font-semibold text-gray-500 mb-2 uppercase tracking-wide">Job Description / Uraian Tugas</h5>
                                                {selectedOrg.description ? (
                                                    <p className="text-gray-700 whitespace-pre-line leading-relaxed">
                                                        {selectedOrg.description}
                                                    </p>
                                                ) : (
                                                    <p className="text-gray-400 italic">Belum ada deskripsi jabatan untuk bagian ini.</p>
                                                )}
                                            </div>

                                            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 pt-4 border-t border-gray-100">
                                                <div>
                                                    <span className="text-xs text-gray-400 block uppercase">Address</span>
                                                    <p className="text-gray-900 text-sm">{selectedOrg.address || '-'}</p>
                                                </div>
                                                <div>
                                                    <span className="text-xs text-gray-400 block uppercase">Contact</span>
                                                    <p className="text-gray-900 text-sm">{selectedOrg.email || '-'}</p>
                                                    <p className="text-gray-900 text-sm">{selectedOrg.phone || '-'}</p>
                                                </div>
                                            </div>
                                        </div>
                                    ) : (
                                        <div className="text-center py-12 bg-gray-50 rounded-lg border border-dashed border-gray-200">
                                            <p className="text-gray-500">Klik salah satu kotak organisasi di atas untuk melihat uraian jabatan dan detail lainnya.</p>
                                        </div>
                                    )}
                                </div>
                            </div>
                        </div>
                    </>
                )}
            </div>

            <OrganizationForm
                isOpen={showForm}
                onClose={() => setShowForm(false)}
                onSuccess={handleFormSuccess}
                initialData={editingOrg}
                organizations={organizations}
                defaultParentId={defaultParentId}
            />
        </DashboardLayout>
    );
}
