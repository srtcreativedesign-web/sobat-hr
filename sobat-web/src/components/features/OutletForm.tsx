'use client';

import { useState, useEffect } from 'react';
import apiClient from '@/lib/api-client';
import { 
  Loader2, 
  X, 
  MapPin, 
  Building, 
  Globe, 
  Navigation,
  Target,
  Info,
  Check
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

interface Organization {
    id: number;
    name: string;
    code: string;
    type: string;
    parent_id?: number | null;
    address?: string;
    phone?: string;
    email?: string;
    latitude?: number | null;
    longitude?: number | null;
    radius_meters?: number | null;
}

interface OutletFormProps {
    isOpen: boolean;
    onClose: () => void;
    onSuccess: () => void;
    initialData?: Organization | null;
}

export default function OutletForm({ isOpen, onClose, onSuccess, initialData }: OutletFormProps) {
    const [divisions, setDivisions] = useState<Organization[]>([]);
    const [formData, setFormData] = useState({
        brand: '',
        division_id: '',
        location_code: '',
        address: '',
        latitude: '',
        longitude: '',
        radius_meters: '100',
    });
    const [loading, setLoading] = useState(false);
    const [fetchingDivisions, setFetchingDivisions] = useState(false);
    const [error, setError] = useState('');

    useEffect(() => {
        if (isOpen) {
            fetchDivisions();
        }
    }, [isOpen]);

    useEffect(() => {
        if (initialData) {
            const nameParts = initialData.name.split('-');
            const brand = nameParts[0] || '';
            const locationCode = nameParts.slice(1).join('-') || '';

            setFormData({
                brand: brand,
                division_id: initialData.parent_id?.toString() || '',
                location_code: locationCode || initialData.code,
                address: initialData.address || '',
                latitude: initialData.latitude?.toString() || '',
                longitude: initialData.longitude?.toString() || '',
                radius_meters: initialData.radius_meters?.toString() || '100',
            });
        } else {
            setFormData({
                brand: 'KINGTECH',
                division_id: '',
                location_code: '',
                address: '',
                latitude: '',
                longitude: '',
                radius_meters: '100',
            });
        }
        setError('');
    }, [initialData, isOpen]);

    const fetchDivisions = async () => {
        setFetchingDivisions(true);
        try {
            const response = await apiClient.get('/divisions');
            // Assuming response.data contains the list of divisions
            setDivisions(response.data.data || response.data);
        } catch (err) {
            console.error('Failed to fetch divisions', err);
        } finally {
            setFetchingDivisions(false);
        }
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError('');

        const finalName = `${formData.brand}-${formData.location_code}`.toUpperCase();

        const payload = {
            name: finalName,
            code: formData.location_code.toUpperCase(),
            type: 'branch',
            parent_id: formData.division_id ? parseInt(formData.division_id) : null,
            address: formData.address || null,
            latitude: formData.latitude ? parseFloat(formData.latitude) : null,
            longitude: formData.longitude ? parseFloat(formData.longitude) : null,
            radius_meters: parseInt(formData.radius_meters),
        };

        try {
            if (initialData) {
                await apiClient.put(`/organizations/${initialData.id}`, payload);
            } else {
                await apiClient.post('/organizations', payload);
            }
            onSuccess();
            onClose();
        } catch (err: any) {
            console.error('Save Error:', err);
            if (err.response?.status === 422 && err.response?.data?.errors) {
                const validationErrors = Object.values(err.response.data.errors).flat().join('\n');
                setError(validationErrors);
            } else {
                setError(err.response?.data?.message || 'Gagal menyimpan data outlet');
            }
        } finally {
            setLoading(false);
        }
    };

    if (!isOpen) return null;

    return (
        <AnimatePresence>
            <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 sm:p-6 overflow-y-auto">
                <motion.div 
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                    onClick={onClose}
                    className="absolute inset-0 bg-slate-900/60 backdrop-blur-md" 
                />
                
                <motion.div 
                    initial={{ opacity: 0, scale: 0.95, y: 20 }}
                    animate={{ opacity: 1, scale: 1, y: 0 }}
                    exit={{ opacity: 0, scale: 0.95, y: 20 }}
                    transition={{ type: "spring", duration: 0.5, bounce: 0.3 }}
                    className="relative bg-white rounded-[2rem] shadow-2xl w-full max-w-xl overflow-hidden border border-white/20 select-none"
                >
                    {/* Premium Header */}
                    <div className="relative p-8 pb-4">
                        <div className="flex justify-between items-start">
                            <div className="space-y-1">
                                <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-indigo-50 text-indigo-600 text-[10px] font-black uppercase tracking-[0.2em]">
                                    <Target className="w-3 h-3" />
                                    Outlet Configuration
                                </div>
                                <h2 className="text-3xl font-black text-slate-900 tracking-tight">
                                    {initialData ? 'Edit' : 'Setup'} <span className="text-indigo-600">Location</span>
                                </h2>
                                <p className="text-slate-400 text-sm font-medium">Configure operational branch parameters</p>
                            </div>
                            <button 
                                onClick={onClose}
                                className="p-2.5 bg-slate-50 hover:bg-red-50 text-slate-400 hover:text-red-500 rounded-2xl transition-all duration-300 group"
                            >
                                <X className="w-5 h-5 group-hover:rotate-90 transition-transform duration-300" />
                            </button>
                        </div>
                    </div>

                    <form onSubmit={handleSubmit} className="p-8 pt-4 space-y-8">
                        {error && (
                            <motion.div 
                                initial={{ opacity: 0, x: -10 }}
                                animate={{ opacity: 1, x: 0 }}
                                className="p-4 bg-rose-50 border border-rose-100 rounded-2xl flex items-start gap-3"
                            >
                                <div className="w-5 h-5 rounded-full bg-rose-500 flex items-center justify-center shrink-0 mt-0.5">
                                    <X className="w-3 h-3 text-white" strokeWidth={3} />
                                </div>
                                <p className="text-xs font-bold text-rose-700 leading-relaxed">{error}</p>
                            </motion.div>
                        )}

                        <div className="space-y-6">
                            {/* Brand & Division Row */}
                            <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
                                <div className="space-y-2">
                                    <label className="text-xs font-black text-slate-500 uppercase tracking-widest ml-1">Brand Identity</label>
                                    <div className="group relative">
                                        <div className="absolute inset-y-0 left-4 flex items-center text-slate-400 group-focus-within:text-indigo-500 transition-colors">
                                            <Globe className="w-4 h-4" />
                                        </div>
                                        <input
                                            type="text"
                                            required
                                            className="w-full pl-12 pr-4 py-4 bg-slate-50 border-2 border-transparent focus:border-indigo-100 focus:bg-white rounded-[1.25rem] outline-none transition-all duration-300 font-bold text-slate-700 placeholder:text-slate-300 ring-4 ring-transparent focus:ring-indigo-50/50"
                                            value={formData.brand}
                                            onChange={(e) => setFormData({ ...formData, brand: e.target.value })}
                                            placeholder="e.g. KINGTECH"
                                        />
                                    </div>
                                </div>
                                <div className="space-y-2">
                                    <label className="text-xs font-black text-slate-500 uppercase tracking-widest ml-1">Division Connection</label>
                                    <div className="relative">
                                        <div className="absolute inset-y-0 left-4 flex items-center text-slate-400 pointer-events-none">
                                            <Building className="w-4 h-4" />
                                        </div>
                                        <select
                                            required
                                            className="w-full pl-12 pr-10 py-4 bg-slate-50 border-2 border-transparent focus:border-indigo-100 focus:bg-white rounded-[1.25rem] outline-none transition-all duration-300 font-bold text-slate-700 appearance-none ring-4 ring-transparent focus:ring-indigo-50/50"
                                            value={formData.division_id}
                                            onChange={(e) => setFormData({ ...formData, division_id: e.target.value })}
                                            disabled={fetchingDivisions}
                                        >
                                            <option value="">Select Division</option>
                                            {divisions.map((div) => (
                                                <option key={div.id} value={div.id}>{div.name}</option>
                                            ))}
                                        </select>
                                        <div className="absolute inset-y-0 right-4 flex items-center pointer-events-none text-slate-400">
                                            {fetchingDivisions ? <Loader2 className="w-4 h-4 animate-spin text-indigo-500" /> : <MapPin className="w-4 h-4" />}
                                        </div>
                                    </div>
                                </div>
                            </div>

                            {/* Manual Location Code */}
                            <div className="space-y-2">
                                <label className="text-xs font-black text-slate-500 uppercase tracking-widest ml-1 flex justify-between">
                                    Manual Location Code
                                    <span className="text-indigo-500 font-black">PREVIEW: {formData.brand || 'BRAND'}-{formData.location_code || 'CODE'}</span>
                                </label>
                                <div className="group relative">
                                    <div className="absolute inset-y-0 left-4 flex items-center text-slate-400 group-focus-within:text-indigo-500 transition-colors">
                                        <Navigation className="w-4 h-4" />
                                    </div>
                                    <input
                                        type="text"
                                        required
                                        className="w-full pl-12 pr-4 py-4 bg-slate-50 border-2 border-transparent focus:border-indigo-100 focus:bg-white rounded-[1.25rem] outline-none transition-all duration-300 font-black text-slate-800 uppercase tracking-widest ring-4 ring-transparent focus:ring-indigo-50/50"
                                        value={formData.location_code}
                                        onChange={(e) => setFormData({ ...formData, location_code: e.target.value })}
                                        placeholder="e.g. T3F-CGK"
                                    />
                                </div>
                            </div>

                            {/* Geo Data Card */}
                            <div className="relative group p-6 rounded-[2rem] bg-indigo-50/30 border border-indigo-100/50 overflow-hidden">
                                <div className="absolute top-0 right-0 p-4 opacity-10 group-focus-within:opacity-20 transition-opacity">
                                    <MapPin className="w-24 h-24 -mr-8 -mt-8 text-indigo-600" />
                                </div>
                                
                                <div className="relative space-y-4">
                                    <div className="flex items-center gap-2 text-indigo-600 font-black text-[10px] uppercase tracking-tighter">
                                        <Target className="w-3.5 h-3.5" />
                                        Precise Geo-Fencing Configuration
                                    </div>
                                    
                                    <div className="grid grid-cols-2 gap-4">
                                        <div className="space-y-1.5">
                                            <input
                                                type="number"
                                                step="any"
                                                className="w-full px-4 py-3 bg-white/80 backdrop-blur-sm border border-indigo-100 rounded-xl outline-none focus:ring-2 focus:ring-indigo-500/20 transition-all text-xs font-bold text-slate-800"
                                                value={formData.latitude}
                                                onChange={(e) => setFormData({ ...formData, latitude: e.target.value })}
                                                placeholder="Latitude (-6.2088)"
                                            />
                                        </div>
                                        <div className="space-y-1.5">
                                            <input
                                                type="number"
                                                step="any"
                                                className="w-full px-4 py-3 bg-white/80 backdrop-blur-sm border border-indigo-100 rounded-xl outline-none focus:ring-2 focus:ring-indigo-500/20 transition-all text-xs font-bold text-slate-800"
                                                value={formData.longitude}
                                                onChange={(e) => setFormData({ ...formData, longitude: e.target.value })}
                                                placeholder="Longitude (106.8456)"
                                            />
                                        </div>
                                    </div>
                                    
                                    <div className="flex items-center gap-4">
                                        <div className="flex-1 space-y-1.5">
                                            <div className="relative">
                                                <input
                                                    type="number"
                                                    className="w-full pl-4 pr-12 py-3 bg-white/80 backdrop-blur-sm border border-indigo-100 rounded-xl outline-none focus:ring-2 focus:ring-indigo-500/20 transition-all text-sm font-black text-indigo-600"
                                                    value={formData.radius_meters}
                                                    onChange={(e) => setFormData({ ...formData, radius_meters: e.target.value })}
                                                />
                                                <span className="absolute right-4 top-1/2 -translate-y-1/2 text-[10px] font-black text-indigo-300">METERS</span>
                                            </div>
                                        </div>
                                        <div className="hidden sm:flex items-center gap-2 px-3 py-2 rounded-xl bg-indigo-100/50 text-indigo-600 text-[10px] font-bold border border-indigo-200/50 max-w-[120px]">
                                            <Info className="w-3.5 h-3.5 shrink-0" />
                                            Optimal radius is between 50-200m
                                        </div>
                                    </div>
                                </div>
                            </div>

                            {/* Full Address */}
                            <div className="space-y-2">
                                <label className="text-xs font-black text-slate-500 uppercase tracking-widest ml-1">Office Physical Address</label>
                                <textarea
                                    className="w-full px-5 py-4 bg-slate-50 border-2 border-transparent focus:border-indigo-100 focus:bg-white rounded-[1.5rem] outline-none transition-all duration-300 text-sm font-medium text-slate-600 min-h-[100px] resize-none ring-4 ring-transparent focus:ring-indigo-50/50"
                                    value={formData.address}
                                    onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                                    placeholder="Enter complete physical address details..."
                                />
                            </div>
                        </div>

                        {/* Action Buttons */}
                        <div className="flex flex-col sm:flex-row gap-4 pt-4">
                            <button
                                type="button"
                                onClick={onClose}
                                className="order-2 sm:order-1 flex-1 px-8 py-4 bg-slate-50 text-slate-500 font-black rounded-2xl hover:bg-slate-100 hover:text-slate-600 transition-all duration-300 text-xs tracking-widest uppercase"
                            >
                                Cancel
                            </button>
                            <button
                                type="submit"
                                disabled={loading}
                                className="order-1 sm:order-2 flex-[2] px-8 py-4 bg-indigo-600 text-white font-black rounded-2xl hover:bg-indigo-700 shadow-xl shadow-indigo-600/20 hover:shadow-indigo-600/30 hover:-translate-y-1 transition-all duration-300 disabled:opacity-50 text-xs tracking-widest uppercase flex items-center justify-center gap-3"
                            >
                                {loading ? (
                                    <Loader2 className="w-5 h-5 animate-spin" />
                                ) : (
                                    <>
                                        <Check className="w-5 h-5" strokeWidth={3} />
                                        Save Configuration
                                    </>
                                )}
                            </button>
                        </div>
                    </form>
                </motion.div>
            </div>
        </AnimatePresence>
    );
}
