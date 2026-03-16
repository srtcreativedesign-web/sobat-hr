'use client';

import React, { useState, useEffect } from 'react';
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
  Map as MapIcon,
  Loader2,
  ExternalLink,
  Navigation,
  Target,
  ChevronRight,
  Monitor,
  LayoutGrid,
  Filter
} from 'lucide-react';
import Swal from 'sweetalert2';
import OutletForm from './OutletForm';
import { motion, AnimatePresence } from 'framer-motion';

const OutletManagement = () => {
    const [outlets, setOutlets] = useState<Organization[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchQuery, setSearchQuery] = useState('');
    const [showForm, setShowForm] = useState(false);
    const [editingOutlet, setEditingOutlet] = useState<Organization | null>(null);

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
        { label: 'Total Outlets', value: outlets.length, color: 'indigo', icon: Building2 },
        { label: 'Active Regions', value: [...new Set(outlets.map(o => o.parent_id))].length, color: 'blue', icon: LayoutGrid },
        { label: 'GPS Secured', value: outlets.filter(o => o.latitude).length, color: 'emerald', icon: MapPin },
    ];

    return (
        <div className="max-w-[1600px] mx-auto space-y-8 select-none">
            {/* Super Premium Header */}
            <div className="relative overflow-hidden bg-slate-900 rounded-[2.5rem] p-10 shadow-2xl shadow-indigo-500/10">
                <div className="absolute top-0 right-0 p-12 opacity-10 blur-2xl">
                    <Building2 className="w-64 h-64 text-indigo-500 rotate-12" />
                </div>
                
                <div className="relative flex flex-col lg:flex-row justify-between items-start lg:items-center gap-8">
                    <div className="space-y-3">
                        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-indigo-500/10 border border-indigo-500/20 text-indigo-400 text-[10px] font-black uppercase tracking-[0.2em]">
                            <Monitor className="w-3 h-3" />
                            Operational Logistics
                        </div>
                        <h1 className="text-4xl sm:text-5xl font-black text-white tracking-tight">
                            Outlet <span className="text-indigo-400">Hub</span>
                        </h1>
                        <p className="text-slate-400 text-lg font-medium max-w-xl leading-relaxed">
                            Pusat kendali lokasi strategis dan parameter geofencing untuk sistem kehadiran global.
                        </p>
                    </div>
                    <motion.button
                        whileHover={{ scale: 1.05, y: -2 }}
                        whileTap={{ scale: 0.95 }}
                        onClick={handleCreate}
                        className="group px-8 py-5 bg-indigo-600 text-white font-black rounded-[1.5rem] shadow-xl shadow-indigo-600/30 hover:shadow-indigo-600/40 transition-all flex items-center gap-3 border border-indigo-500/50"
                    >
                        <Plus className="w-6 h-6 group-hover:rotate-180 transition-transform duration-500" />
                        Tambah Cabang Baru
                    </motion.button>
                </div>

                {/* Micro Stats Grid */}
                <div className="grid grid-cols-2 lg:grid-cols-3 gap-4 mt-10 max-w-3xl">
                    {stats.map((stat, i) => (
                        <div key={i} className="flex items-center gap-4 bg-white/5 backdrop-blur-md p-4 rounded-2xl border border-white/10">
                            <div className={`p-2 rounded-xl bg-${stat.color}-500/10 text-${stat.color}-400`}>
                                <stat.icon className="w-5 h-5" />
                            </div>
                            <div>
                                <div className="text-[10px] font-black text-slate-500 uppercase tracking-widest">{stat.label}</div>
                                <div className="text-xl font-black text-white">{stat.value}</div>
                            </div>
                        </div>
                    ))}
                </div>
            </div>

            {/* Filter Hub */}
            <div className="flex flex-col md:flex-row items-center gap-4">
                <div className="relative flex-1 group w-full">
                    <div className="absolute inset-y-0 left-5 flex items-center text-slate-400 group-focus-within:text-indigo-500 transition-colors">
                        <Search className="w-5 h-5 transition-transform group-focus-within:scale-110" />
                    </div>
                    <input 
                        type="text" 
                        placeholder="Search by brand, code, or address details..." 
                        className="w-full pl-14 pr-6 py-5 bg-white border border-slate-100 rounded-[1.5rem] shadow-sm focus:ring-4 focus:ring-indigo-50 focus:border-indigo-100 transition-all outline-none text-sm font-bold text-slate-700 placeholder:text-slate-300"
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                    />
                </div>
                <button className="p-5 bg-white border border-slate-100 rounded-[1.5rem] text-slate-400 hover:text-indigo-600 transition-all shadow-sm">
                    <Filter className="w-6 h-6" />
                </button>
            </div>

            {/* Premium Table Container */}
            <div className="bg-white rounded-[2.5rem] border border-slate-100 shadow-xl shadow-slate-200/50 overflow-hidden min-h-[400px]">
                <div className="overflow-x-auto">
                    <table className="w-full text-left border-collapse">
                        <thead>
                            <tr className="bg-slate-50/50 border-b border-slate-100">
                                <th className="px-8 py-6 text-[11px] font-black text-slate-400 uppercase tracking-[0.2em]">Cabang & Brand</th>
                                <th className="px-8 py-6 text-[11px] font-black text-slate-400 uppercase tracking-[0.2em]">Logistic Info</th>
                                <th className="px-8 py-6 text-[11px] font-black text-slate-400 uppercase tracking-[0.2em]">GPS Mapping</th>
                                <th className="px-8 py-6 text-[11px] font-black text-slate-400 uppercase tracking-[0.2em]">Precision Radius</th>
                                <th className="px-8 py-6 text-[11px] font-black text-slate-400 uppercase tracking-[0.2em] text-right">Settings</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-50">
                            {loading ? (
                                Array(5).fill(0).map((_, i) => (
                                    <tr key={i} className="animate-pulse">
                                        <td colSpan={5} className="px-8 py-8">
                                            <div className="flex gap-4">
                                                <div className="w-12 h-12 bg-slate-50 rounded-2xl"></div>
                                                <div className="flex-1 space-y-3">
                                                    <div className="h-4 bg-slate-50 rounded-lg w-1/3"></div>
                                                    <div className="h-3 bg-slate-50 rounded-lg w-1/4"></div>
                                                </div>
                                            </div>
                                        </td>
                                    </tr>
                                ))
                            ) : filteredOutlets.length === 0 ? (
                                <tr>
                                    <td colSpan={5} className="px-8 py-32 text-center">
                                        <motion.div 
                                            initial={{ opacity: 0, y: 10 }}
                                            animate={{ opacity: 1, y: 0 }}
                                            className="space-y-4"
                                        >
                                            <div className="w-24 h-24 bg-slate-50 rounded-[2rem] mx-auto flex items-center justify-center text-slate-200">
                                                <Building2 className="w-12 h-12" />
                                            </div>
                                            <div className="space-y-1">
                                                <p className="text-slate-900 font-black tracking-tight">No Operational Outlets Found</p>
                                                <p className="text-slate-400 text-sm font-medium">Try adjusting your search or add a new location configuration.</p>
                                            </div>
                                        </motion.div>
                                    </td>
                                </tr>
                            ) : (
                                <AnimatePresence mode="popLayout">
                                    {filteredOutlets.map((outlet, index) => (
                                        <motion.tr 
                                            key={outlet.id}
                                            initial={{ opacity: 0, x: -10 }}
                                            animate={{ opacity: 1, x: 0 }}
                                            transition={{ delay: index * 0.03 }}
                                            className="group hover:bg-slate-50/80 transition-all duration-300"
                                        >
                                            <td className="px-8 py-6">
                                                <div className="flex items-center gap-4">
                                                    <div className="relative w-14 h-14 shrink-0">
                                                        <div className="absolute inset-0 bg-indigo-600/5 rotate-12 group-hover:rotate-0 transition-transform duration-500 rounded-2xl"></div>
                                                        <div className="relative w-full h-full rounded-2xl bg-white border border-indigo-50 flex items-center justify-center text-indigo-600 shadow-sm group-hover:shadow-md transition-all">
                                                            <Building2 className="w-6 h-6" />
                                                        </div>
                                                    </div>
                                                    <div>
                                                        <div className="font-black text-slate-900 tracking-tight text-[15px]">{outlet.name}</div>
                                                        <div className="text-[10px] bg-slate-100 text-slate-500 px-2 py-0.5 rounded-md inline-block mt-1 font-black uppercase tracking-wider">{outlet.code}</div>
                                                    </div>
                                                </div>
                                            </td>
                                            <td className="px-8 py-6">
                                                <div className="space-y-2">
                                                    {outlet.address && (
                                                        <div className="flex items-start gap-2.5 text-xs font-bold text-slate-500 max-w-[250px] leading-relaxed">
                                                            <MapPin className="w-3.5 h-3.5 text-indigo-400 shrink-0 mt-0.5" />
                                                            <span className="line-clamp-2">{outlet.address}</span>
                                                        </div>
                                                    )}
                                                    {outlet.phone && (
                                                        <div className="flex items-center gap-2.5 text-[11px] font-black text-slate-400">
                                                            <Phone className="w-3.5 h-3.5 text-indigo-400 shrink-0" />
                                                            {outlet.phone}
                                                        </div>
                                                    )}
                                                </div>
                                            </td>
                                            <td className="px-8 py-6">
                                                {outlet.latitude && outlet.longitude ? (
                                                    <a 
                                                        href={`https://www.google.com/maps?q=${outlet.latitude},${outlet.longitude}`}
                                                        target="_blank"
                                                        rel="noopener noreferrer"
                                                        className="inline-flex items-center gap-2.5 px-4 py-2.5 rounded-xl bg-indigo-50 text-indigo-700 text-[11px] font-black hover:bg-indigo-600 hover:text-white transition-all shadow-sm group/map"
                                                    >
                                                        <Navigation className="w-3.5 h-3.5 group-hover/map:scale-110 transition-transform" />
                                                        {outlet.latitude.toFixed(4)}, {outlet.longitude.toFixed(4)}
                                                        <ExternalLink className="w-3 h-3 ml-1 opacity-50 group-hover/map:opacity-100" />
                                                    </a>
                                                ) : (
                                                    <div className="inline-flex items-center gap-2 px-3 py-2 rounded-xl bg-slate-50 text-slate-300 text-[10px] font-bold italic border border-dashed border-slate-200">
                                                        Not mapped
                                                    </div>
                                                )}
                                            </td>
                                            <td className="px-8 py-6">
                                                <div className="flex items-center gap-4">
                                                    <div className="w-24 h-2 bg-slate-100 rounded-full overflow-hidden">
                                                        <motion.div 
                                                            initial={{ width: 0 }}
                                                            animate={{ width: `${Math.min(100, (outlet.radius_meters || 100) / 4)}%` }}
                                                            className="h-full bg-indigo-600 rounded-full" 
                                                        />
                                                    </div>
                                                    <div className="flex items-center gap-1">
                                                        <span className="text-sm font-black text-slate-900">{outlet.radius_meters || 100}</span>
                                                        <span className="text-[10px] font-black text-slate-400">meters</span>
                                                    </div>
                                                </div>
                                            </td>
                                            <td className="px-8 py-6 text-right">
                                                <div className="flex items-center justify-end gap-3 translate-x-4 opacity-0 group-hover:translate-x-0 group-hover:opacity-100 transition-all duration-300">
                                                    <button 
                                                        onClick={() => handleEdit(outlet)}
                                                        className="p-3 bg-white text-indigo-600 hover:bg-indigo-600 hover:text-white rounded-xl shadow-sm border border-slate-100 transition-all active:scale-95"
                                                        title="Edit Parameter"
                                                    >
                                                        <Edit3 className="w-4 h-4" />
                                                    </button>
                                                    <button 
                                                        onClick={() => handleDelete(outlet.id)}
                                                        className="p-3 bg-white text-rose-500 hover:bg-rose-500 hover:text-white rounded-xl shadow-sm border border-slate-100 transition-all active:scale-95"
                                                        title="Remove Outlet"
                                                    >
                                                        <Trash2 className="w-4 h-4" />
                                                    </button>
                                                </div>
                                            </td>
                                        </motion.tr>
                                    ))}
                                </AnimatePresence>
                            )}
                        </tbody>
                    </table>
                </div>
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
        </div>
    );
};

export default OutletManagement;
