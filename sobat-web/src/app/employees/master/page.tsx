'use client';

import { useState, useEffect } from 'react';
import DashboardLayout from '@/components/DashboardLayout';
import apiClient from '@/lib/api-client';
import EmployeeForm from '../components/EmployeeForm';
import { DataTable } from '@/components/ui/data-table';
import { User, Chip, Button, Input } from '@nextui-org/react';
import { Search } from 'lucide-react';

export default function EmployeeMasterPage() {
    const [employees, setEmployees] = useState<any[]>([]);
    const [organizations, setOrganizations] = useState<any[]>([]);
    const [divisions, setDivisions] = useState<any[]>([]);
    const [jobPositions, setJobPositions] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [showForm, setShowForm] = useState(false);
    const [selectedEmployee, setSelectedEmployee] = useState<any>(null);

    useEffect(() => {
        fetchData();
    }, []);

    const fetchData = async () => {
        setLoading(true);
        try {
            const [empRes, orgRes, divRes, posRes] = await Promise.all([
                apiClient.get('/employees'), // Fetch all employees
                apiClient.get('/organizations'),
                apiClient.get('/divisions'),
                apiClient.get('/job-positions')
            ]);
            setEmployees(empRes.data.data || empRes.data || []);
            setOrganizations(orgRes.data.data || orgRes.data || []);
            setDivisions(divRes.data.data || divRes.data || []);
            setJobPositions(posRes.data.data || posRes.data || []);
        } catch (error) {
            console.error('Failed to fetch data', error);
        } finally {
            setLoading(false);
        }
    };

    const handleSearch = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        try {
            const response = await apiClient.get(`/employees?search=${searchTerm}`);
            setEmployees(response.data.data || response.data || []);
        } catch (error) {
            console.error('Search failed', error);
        } finally {
            setLoading(false);
        }
    };

    const handleEdit = (employee: any) => {
        setSelectedEmployee(employee);
        setShowForm(true);
    };

    const handleAddNew = () => {
        setSelectedEmployee(null);
        setShowForm(true);
    };

    const handleFormSuccess = () => {
        fetchData();
    };

    const getStatusBadge = (status: string) => {
        const styles = {
            active: 'bg-green-100 text-green-800',
            inactive: 'bg-gray-100 text-gray-800',
            resigned: 'bg-red-100 text-red-800'
        };
        return styles[status as keyof typeof styles] || styles.inactive;
    };

    const isExpiringSoon = (dateString: string) => {
        if (!dateString) return false;
        const end = new Date(dateString);
        const now = new Date();
        const diffTime = end.getTime() - now.getTime();
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        return diffDays <= 30 && diffDays >= 0;
    };

    const columns = [
        { name: "KARYAWAN", uid: "employee" },
        { name: "JABATAN & DIVISI", uid: "position" },
        { name: "SISA CUTI", uid: "leave" },
        { name: "STATUS", uid: "status" },
        { name: "KONTRAK BERAKHIR", uid: "contract" },
        { name: "ACTIONS", uid: "actions" },
    ];

    const renderCell = (emp: any, columnKey: React.Key) => {
        switch (columnKey) {
            case "employee":
                return (
                    <User
                        avatarProps={{ radius: "lg", name: emp.full_name?.[0]?.toUpperCase() }}
                        description={emp.employee_code}
                        name={emp.full_name}
                    >
                        {emp.full_name}
                    </User>
                );
            case "position":
                return (
                    <div className="flex flex-col">
                        <p className="text-bold text-sm capitalize">{emp.position || '-'}</p>
                        <p className="text-bold text-sm capitalize text-default-400">{emp.division?.name || '-'}</p>
                    </div>
                );
            case "leave":
                return (
                    <Chip className="capitalize" color={emp.leave_balance !== '-' ? "success" : "default"} size="sm" variant="flat">
                        {emp.leave_balance || '-'}
                    </Chip>
                );
            case "status":
                const statusColorMap: Record<string, "success" | "danger" | "warning" | "default"> = {
                    active: "success",
                    resigned: "danger",
                    inactive: "default",
                };
                return (
                    <Chip className="capitalize" color={statusColorMap[emp.status?.toLowerCase()] || "default"} size="sm" variant="flat">
                        {emp.status}
                    </Chip>
                );
            case "contract":
                return emp.contract_end_date ? (
                    <div className="flex flex-col">
                        <p className="text-sm">{new Date(emp.contract_end_date).toLocaleDateString('id-ID')}</p>
                        {isExpiringSoon(emp.contract_end_date) && (
                            <Chip size="sm" color="danger" variant="flat" className="mt-1">
                                Expiring Soon
                            </Chip>
                        )}
                    </div>
                ) : <p className="text-sm">-</p>;
            case "actions":
                return (
                    <Button color="primary" variant="light" size="sm" onPress={() => handleEdit(emp)}>
                        Edit Lengkap
                    </Button>
                );
            default:
                return null;
        }
    };

    return (
        <DashboardLayout>
            <div className="p-6">
                <div className="flex justify-between items-center mb-6">
                    <div>
                        <h1 className="text-2xl font-bold text-[#419cc3]">Master Data Karyawan</h1>
                        <p className="text-gray-500">Kelola data lengkap seluruh karyawan.</p>
                    </div>
                    <button
                        onClick={handleAddNew}
                        className="px-4 py-2 bg-[#419cc3] text-white rounded-lg hover:bg-[#2d1e24] font-medium flex items-center gap-2"
                    >
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" /></svg>
                        Tambah Manual
                    </button>
                </div>

                {/* Search */}
                <div className="bg-white p-4 rounded-xl shadow-sm mb-6 border border-gray-100">
                    <form onSubmit={handleSearch} className="flex gap-4">
                        <Input
                            isClearable
                            classNames={{
                                base: "flex-1",
                                inputWrapper: "border border-gray-200 bg-white hover:bg-gray-50 focus-within:ring-2 focus-within:ring-[#89b4e1] h-full",
                            }}
                            placeholder="Cari nama atau NIK..."
                            startContent={<Search className="text-gray-400" size={18} />}
                            value={searchTerm}
                            onClear={() => setSearchTerm('')}
                            onChange={(e) => setSearchTerm(e.target.value)}
                        />
                        <Button 
                            type="submit" 
                            color="primary" 
                            className="px-6 font-bold bg-[#89b4e1] text-[#419cc3]"
                        >
                            Cari
                        </Button>
                    </form>
                </div>

                {/* Table */}
                <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
                    <DataTable
                        columns={columns}
                        data={employees}
                        isLoading={loading}
                        renderCell={renderCell}
                        primaryKey="id"
                    />
                </div>
            </div>

            <EmployeeForm
                isOpen={showForm}
                onClose={() => setShowForm(false)}
                onSuccess={handleFormSuccess}
                initialData={selectedEmployee}
                organizations={organizations}
                divisions={divisions}
                jobPositions={jobPositions}
            />
        </DashboardLayout>
    );
}
