'use client';

import { useEffect, useState, useMemo } from 'react';
import DashboardLayout from '@/components/DashboardLayout';
import apiClient from '@/lib/api-client';
import OrganizationTree from '../components/OrganizationTree';
import OrganizationForm from '../components/OrganizationForm';

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

export default function DivisionsPage() {
    const [allOrganizations, setAllOrganizations] = useState<Organization[]>([]);
    const [selectedDivisionId, setSelectedDivisionId] = useState<number | null>(null);
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
            // Same endpoint as global org chart
            const response = await apiClient.get('/organizations');
            setAllOrganizations(response.data);
        } catch (error) {
            console.error('Failed to fetch orgs:', error);
        } finally {
            setLoading(false);
        }
    };

    // Get divisions from global data — filter orgs with type 'Division'
    const divisions = useMemo(() => {
        return allOrganizations
            .filter(o => o.type?.toLowerCase() === 'division')
            .sort((a, b) => a.name.localeCompare(b.name));
    }, [allOrganizations]);

    // Auto-select first division
    useEffect(() => {
        if (divisions.length > 0 && !selectedDivisionId) {
            setSelectedDivisionId(divisions[0].id);
        }
    }, [divisions, selectedDivisionId]);

    // Build sub-tree for selected division
    const divisionTree = useMemo(() => {
        if (!selectedDivisionId) return [];

        const getDescendants = (parentId: number): Organization[] => {
            const children = allOrganizations.filter(o => o.parent_id === parentId);
            let result: Organization[] = [];
            for (const child of children) {
                result.push(child);
                result = result.concat(getDescendants(child.id));
            }
            return result;
        };

        const root = allOrganizations.find(o => o.id === selectedDivisionId);
        if (!root) return [];
        return [root, ...getDescendants(selectedDivisionId)];
    }, [allOrganizations, selectedDivisionId]);

    const selectedDivision = divisions.find(d => d.id === selectedDivisionId);

    const handleCreate = () => {
        setEditingOrg(null);
        setDefaultParentId(selectedDivisionId);
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
        setDefaultParentId(child.parent_id || null);
        setTargetChildId(child.id);
        setShowForm(true);
    };

    const handleFormSuccess = async (newOrg?: Organization) => {
        if (targetChildId && newOrg) {
            try {
                await apiClient.put(`/organizations/${targetChildId}`, {
                    parent_id: newOrg.id
                });
            } catch (error) {
                console.error('Failed to link child to new parent', error);
                alert('Organization created, but failed to link as parent.');
            } finally {
                setTargetChildId(null);
            }
        }
        fetchOrganizations();
    };

    const handleDelete = async (id: number) => {
        if (!confirm('Yakin ingin menghapus organisasi ini beserta sub-unitnya?')) return;
        try {
            await apiClient.delete(`/organizations/${id}`);
            fetchOrganizations();
        } catch (error: any) {
            alert(error.response?.data?.message || 'Gagal menghapus');
        }
    };

    const handleSelect = (org: Organization) => {
        setSelectedOrg(org);
    };

    return (
        <DashboardLayout>
            <div className="flex justify-between items-center p-8 pb-0 animate-fade-in-up">
                <div>
                    <h1 className="text-2xl font-bold text-[#1C3ECA]">Struktur Per Divisi</h1>
                    <p className="text-gray-500 mt-1">Bagan organisasi untuk setiap divisi</p>
                </div>
                <div className="flex gap-3 items-center">
                    {/* Division Dropdown - from global org data */}
                    <div className="relative">
                        <select
                            value={selectedDivisionId || ''}
                            onChange={(e) => {
                                setSelectedDivisionId(Number(e.target.value));
                                setSelectedOrg(null);
                            }}
                            className="appearance-none bg-white border border-gray-200 text-gray-800 px-4 py-2.5 pr-10 rounded-xl text-sm font-semibold shadow-sm focus:ring-2 focus:ring-[#60A5FA] focus:border-transparent outline-none transition-all cursor-pointer"
                        >
                            <option value="" disabled>Pilih Divisi...</option>
                            {divisions.map(div => (
                                <option key={div.id} value={div.id}>
                                    {div.name}
                                </option>
                            ))}
                        </select>
                        <svg className="w-4 h-4 absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                        </svg>
                    </div>

                    {selectedDivision && (
                        <button
                            onClick={handleCreate}
                            className="px-4 py-2.5 bg-[#1C3ECA] text-white font-semibold rounded-xl hover:bg-[#162ea0] shadow-lg shadow-[#1C3ECA]/20 transition-all flex items-center gap-2 text-sm"
                        >
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
                            </svg>
                            Tambah Unit
                        </button>
                    )}
                </div>
            </div>

            <div className="p-8">
                {loading ? (
                    <div className="flex items-center justify-center py-12">
                        <div className="w-8 h-8 border-4 border-[#60A5FA] border-t-transparent rounded-full animate-spin"></div>
                    </div>
                ) : !selectedDivision ? (
                    <div className="text-center py-20 bg-white rounded-2xl border border-gray-100 shadow-sm">
                        <svg className="w-16 h-16 mx-auto text-gray-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                        </svg>
                        <p className="text-gray-500 text-lg font-medium">Pilih divisi untuk melihat struktur organisasi</p>
                    </div>
                ) : (
                    <>
                        {/* Division Header Badge */}
                        <div className="mb-4 flex items-center gap-3">
                            <div className="inline-flex items-center gap-2 px-4 py-2 bg-[#1C3ECA]/5 border border-[#1C3ECA]/10 rounded-xl">
                                <div className="w-2 h-2 bg-[#1C3ECA] rounded-full"></div>
                                <span className="text-sm font-bold text-[#1C3ECA]">{selectedDivision.name}</span>
                                <span className="text-xs text-gray-500">({divisionTree.length} unit)</span>
                            </div>
                        </div>

                        {/* Organization Chart */}
                        <OrganizationTree
                            organizations={divisionTree}
                            onEdit={handleEdit}
                            onAddChild={handleAddChild}
                            onAddSibling={handleAddSibling}
                            onDelete={handleDelete}
                            onSelect={handleSelect}
                            onAddParent={handleAddParent}
                        />

                        {/* Detail Panel */}
                        <div className="mt-8 animate-fade-in-up" key={selectedOrg?.id || 'empty'}>
                            <div className="glass-card p-6 rounded-xl border border-gray-100 bg-white shadow-sm">
                                <h3 className="text-xl font-bold text-[#1C3ECA] mb-4 flex items-center gap-2">
                                    <svg className="w-5 h-5 text-[#93C5FD]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                                    </svg>
                                    Uraian Jabatan & Detail
                                </h3>

                                {selectedOrg ? (
                                    <div className="space-y-4">
                                        <div className="flex items-start justify-between">
                                            <div>
                                                <h4 className="text-lg font-bold text-gray-900">{selectedOrg.name}</h4>
                                                <p className="text-sm text-gray-500 font-mono mt-1">{selectedOrg.code}</p>
                                                <span className="inline-block px-2 py-1 bg-gray-100 text-gray-600 text-xs rounded-full mt-2 uppercase font-bold">{selectedOrg.type}</span>
                                            </div>
                                            <button onClick={() => handleEdit(selectedOrg)} className="text-[#60A5FA] hover:text-[#93C5FD] text-sm font-semibold">
                                                Edit Details
                                            </button>
                                        </div>

                                        <hr className="border-gray-100" />

                                        <div>
                                            <h5 className="text-sm font-semibold text-gray-500 mb-2 uppercase tracking-wide">Job Description / Uraian Tugas</h5>
                                            {selectedOrg.description ? (
                                                <p className="text-gray-700 whitespace-pre-line leading-relaxed">{selectedOrg.description}</p>
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
                                        <p className="text-gray-500">Klik salah satu kotak organisasi di atas untuk melihat detail.</p>
                                    </div>
                                )}
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
                organizations={divisionTree}
                defaultParentId={defaultParentId}
            />
        </DashboardLayout>
    );
}
