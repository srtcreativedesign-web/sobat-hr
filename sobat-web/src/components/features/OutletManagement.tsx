'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import apiClient from '@/lib/api-client';
import { Organization } from '@/types';
import { 
  Building2, 
  MapPin, 
  Phone, 
  Search, 
  Plus, 
  Edit3, 
  Trash2, 
  Monitor,
  LayoutGrid,
  Filter,
  QrCode
} from 'lucide-react';
import Swal from 'sweetalert2';
import OutletForm from './OutletForm';
import OutletDevicesManager from './OutletDevicesManager';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Table, TableHeader, TableColumn, TableBody, TableRow, TableCell,
  Input, Button, Tooltip, Spinner, Progress, Chip
} from "@nextui-org/react";

const OutletManagement = () => {
    const router = useRouter();
    const [outlets, setOutlets] = useState<Organization[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchQuery, setSearchQuery] = useState('');
    const [showForm, setShowForm] = useState(false);
    const [editingOutlet, setEditingOutlet] = useState<Organization | null>(null);
    const [managingDevicesForOutlet, setManagingDevicesForOutlet] = useState<Organization | null>(null);

    useEffect(() => {
        fetchOutlets();
    }, []);

    const fetchOutlets = async () => {
        setLoading(true);
        try {
            const response = await apiClient.get('/organizations?type=branch');
            setOutlets(response.data);
        } catch (error) {
            console.error('Error fetching outlets:', error);
            Swal.fire({
                icon: 'error',
                title: 'Operation Failed',
                text: 'Gagal memuat data outlet operasional.',
                customClass: {
                    container: 'font-sans',
                    popup: 'rounded-[2rem]',
                    confirmButton: 'rounded-xl bg-indigo-600 px-6 py-2.5 font-bold'
                }
            });
        } finally {
            setLoading(false);
        }
    };

    const handleCreate = () => {
        setEditingOutlet(null);
        setShowForm(true);
    };

    const handleEdit = (outlet: Organization) => {
        setEditingOutlet(outlet);
        setShowForm(true);
    };

    const handleDelete = async (id: number) => {
        const result = await Swal.fire({
            title: 'Hapus Outlet?',
            text: 'Data yang dihapus akan hilang dari sistem absensi.',
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#ef4444',
            confirmButtonText: 'Ya, Hapus Permanen',
            cancelButtonText: 'Batal',
            customClass: {
                popup: 'rounded-[2rem]',
                confirmButton: 'rounded-xl px-4 py-2 font-bold',
                cancelButton: 'rounded-xl px-4 py-2 font-bold'
            }
        });

        if (result.isConfirmed) {
            try {
                await apiClient.delete(`/organizations/${id}`);
                Swal.fire({
                    icon: 'success',
                    title: 'Terhapus!',
                    text: 'Data outlet telah dihapus.',
                    timer: 1500,
                    showConfirmButton: false,
                    customClass: { popup: 'rounded-[2rem]' }
                });
                fetchOutlets();
            } catch (error) {
                Swal.fire({
                    icon: 'error',
                    title: 'Gagal!',
                    text: 'Gagal menghapus data.',
                    customClass: { popup: 'rounded-[2rem]' }
                });
            }
        }
    };

    const filteredOutlets = outlets.filter(o => 
        o.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        o.code.toLowerCase().includes(searchQuery.toLowerCase()) ||
        o.address?.toLowerCase().includes(searchQuery.toLowerCase())
    );

    const stats = [
        { label: 'Total Outlets', value: outlets.length, colorClass: 'bg-white/20 text-white', icon: Building2 },
        { label: 'Active Regions', value: [...new Set(outlets.map(o => o.division_id))].length, colorClass: 'bg-white/20 text-white', icon: LayoutGrid },
    ];

    return (
        <div className="max-w-[1600px] mx-auto space-y-8 select-none">
            {/* Super Premium Header */}
            <div className="relative overflow-hidden bg-gradient-to-r from-[#419CC3] to-[#89B4E1] rounded-[2.5rem] p-10 shadow-2xl shadow-[#419CC3]/30">
                <div className="absolute top-0 right-0 p-12 opacity-20 blur-2xl">
                    <Building2 className="w-64 h-64 text-white rotate-12" />
                </div>
                
                <div className="relative flex flex-col lg:flex-row justify-between items-start lg:items-center gap-8">
                    <div className="space-y-3">
                        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/20 border border-white/30 text-white text-[10px] font-black uppercase tracking-[0.2em] backdrop-blur-md">
                            <Monitor className="w-3 h-3" />
                            Operational Logistics
                        </div>
                        <h1 className="text-4xl sm:text-5xl font-black text-white tracking-tight">
                            Outlet <span className="text-[#e0f2fe]">Hub</span>
                        </h1>
                        <p className="text-white/90 text-lg font-medium max-w-xl leading-relaxed">
                            Pusat kendali lokasi strategis dan parameter geofencing untuk sistem kehadiran global.
                        </p>
                    </div>
                    <Button
                        size="lg"
                        onPress={handleCreate}
                        startContent={<Plus className="w-5 h-5" />}
                        className="bg-white text-[#419CC3] font-black tracking-wide rounded-[1rem] shadow-xl shadow-black/10 px-8 hover:scale-105 transition-transform"
                    >
                        Tambah Cabang Baru
                    </Button>
                </div>

                {/* Micro Stats Grid */}
                <div className="grid grid-cols-2 lg:grid-cols-3 gap-4 mt-10 max-w-3xl relative z-10">
                    {stats.map((stat, i) => (
                        <div key={i} className="flex items-center gap-4 bg-white/10 backdrop-blur-md p-4 rounded-2xl border border-white/20 hover:bg-white/20 transition-colors">
                            <div className={`p-3 rounded-xl ${stat.colorClass}`}>
                                <stat.icon className="w-5 h-5" />
                            </div>
                            <div>
                                <div className="text-[10px] font-black text-white/80 uppercase tracking-widest">{stat.label}</div>
                                <div className="text-2xl font-black text-white">{stat.value}</div>
                            </div>
                        </div>
                    ))}
                </div>
            </div>

            {/* Filter Hub */}
            <div className="flex flex-col md:flex-row items-center gap-4">
                <Input 
                    isClearable
                    className="w-full"
                    placeholder="Search by brand, code, or address details..."
                    startContent={<Search className="text-slate-400" />}
                    value={searchQuery}
                    onClear={() => setSearchQuery("")}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    size="lg"
                    radius="full"
                    classNames={{
                        inputWrapper: "h-14 bg-white hover:bg-white focus-within:!bg-white border border-slate-100 shadow-sm",
                    }}
                />
                <Button 
                    isIconOnly 
                    size="lg"
                    radius="full"
                    className="bg-white border border-slate-100 text-slate-400 shadow-sm"
                >
                    <Filter className="w-5 h-5" />
                </Button>
            </div>

            {/* NextUI Table Container */}
            <div className="bg-white rounded-[2.5rem] border border-slate-100 shadow-xl shadow-slate-200/50 p-4">
                <Table 
                    aria-label="Outlet Management Table"
                    removeWrapper
                    classNames={{
                        th: "bg-slate-50 text-slate-400 font-black uppercase tracking-wider py-4 text-[11px]",
                        td: "py-4 border-b border-slate-50/80",
                    }}
                >
                    <TableHeader>
                        <TableColumn>CABANG & BRAND</TableColumn>
                        <TableColumn>LOGISTIC INFO</TableColumn>
                        <TableColumn>RADIUS</TableColumn>
                        <TableColumn align="center">PERANGKAT MESIN</TableColumn>
                        <TableColumn align="end">ACTIONS</TableColumn>
                    </TableHeader>
                    <TableBody 
                        items={filteredOutlets} 
                        isLoading={loading}
                        loadingContent={<Spinner color="primary" />}
                        emptyContent={!loading && "No Operational Outlets Found"}
                    >
                        {(outlet) => (
                            <TableRow key={outlet.id} className="hover:bg-slate-50/50 transition-colors">
                                <TableCell>
                                    <div className="flex items-center gap-4">
                                        <div className="relative w-12 h-12 shrink-0 flex items-center justify-center bg-indigo-50 rounded-2xl text-indigo-600">
                                            <Building2 className="w-5 h-5" />
                                        </div>
                                        <div>
                                            <div className="font-black text-slate-900 text-sm">{outlet.name}</div>
                                            <Chip size="sm" className="mt-1 bg-slate-100 text-slate-500 font-black uppercase tracking-wider text-[9px] h-5">
                                                {outlet.code}
                                            </Chip>
                                        </div>
                                    </div>
                                </TableCell>
                                <TableCell>
                                    <div className="space-y-1.5">
                                        {outlet.address && (
                                            <div className="flex items-start gap-2 text-xs font-bold text-slate-500 max-w-[200px]">
                                                <MapPin className="w-3.5 h-3.5 text-indigo-400 shrink-0 mt-0.5" />
                                                <span className="line-clamp-2">{outlet.address}</span>
                                            </div>
                                        )}
                                        {outlet.phone && (
                                            <div className="flex items-center gap-2 text-[10px] font-black text-slate-400">
                                                <Phone className="w-3.5 h-3.5 text-indigo-400" />
                                                {outlet.phone}
                                            </div>
                                        )}
                                    </div>
                                </TableCell>
                                <TableCell>
                                    <div className="flex items-center gap-3">
                                        <Progress 
                                            size="sm"
                                            radius="full"
                                            classNames={{
                                                base: "max-w-xs w-24",
                                                indicator: "bg-indigo-500"
                                            }}
                                            value={Math.min(100, (outlet.radius_meters || 100) / 4)} 
                                        />
                                        <div className="flex items-baseline gap-1">
                                            <span className="text-sm font-black text-slate-900">{outlet.radius_meters || 100}</span>
                                            <span className="text-[9px] font-black text-slate-400 uppercase">m</span>
                                        </div>
                                    </div>
                                </TableCell>
                                <TableCell>
                                    <div className="flex items-center justify-center">
                                        <Tooltip content="Kelola Perangkat Sobat Outlet (Mesin Absensi)" placement="top" classNames={{ content: "font-bold text-xs" }}>
                                            <Button 
                                                size="sm" 
                                                color="secondary" 
                                                variant="flat"
                                                startContent={<Monitor className="w-4 h-4" />}
                                                onPress={() => setManagingDevicesForOutlet(outlet)}
                                                className="font-bold text-[10px] uppercase tracking-wider px-4"
                                            >
                                                Daftar Mesin
                                            </Button>
                                        </Tooltip>
                                    </div>
                                </TableCell>
                                <TableCell>
                                    <div className="flex items-center justify-end gap-2">
                                        <Tooltip content="Edit Outlet" color="primary">
                                            <Button isIconOnly variant="light" color="primary" onPress={() => handleEdit(outlet)}>
                                                <Edit3 className="w-4 h-4" />
                                            </Button>
                                        </Tooltip>
                                        <Tooltip content="Hapus Outlet" color="danger">
                                            <Button isIconOnly variant="light" color="danger" onPress={() => handleDelete(outlet.id)}>
                                                <Trash2 className="w-4 h-4" />
                                            </Button>
                                        </Tooltip>
                                    </div>
                                </TableCell>
                            </TableRow>
                        )}
                    </TableBody>
                </Table>
            </div>

            <OutletForm 
                isOpen={showForm}
                onClose={() => setShowForm(false)}
                onSuccess={() => {
                    fetchOutlets();
                    setShowForm(false);
                }}
                initialData={editingOutlet}
            />

            {managingDevicesForOutlet && (
                <OutletDevicesManager 
                    outlet={managingDevicesForOutlet} 
                    onClose={() => setManagingDevicesForOutlet(null)} 
                />
            )}
        </div>
    );
};

export default OutletManagement;
