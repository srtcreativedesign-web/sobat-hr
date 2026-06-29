'use client';

import { useState, useEffect } from 'react';
import apiClient from '@/lib/api-client';
import { 
  Loader2, 
  MapPin,
  Building, 
  Globe, 
  Navigation,
  Target,
  Check,
  MonitorSmartphone,
  Lock
} from 'lucide-react';
import { 
  Modal, ModalContent, ModalHeader, ModalBody, ModalFooter, 
  Button, Input, Select, SelectItem, Textarea 
} from "@nextui-org/react";

interface Organization {
    id: number;
    name: string;
    code: string;
    type: string;
    parent_id?: number | null;
    division_id?: number | null;
    address?: string;
    phone?: string;
    email?: string;
    latitude?: number | null;
    longitude?: number | null;
    radius_meters?: number | null;
    division?: { id: number; name: string };
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
        radius_meters: '100',
        device_code: '',
        device_pin: '',
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
                division_id: initialData.division_id?.toString() || '',
                location_code: locationCode || initialData.code,
                address: initialData.address || '',
                radius_meters: initialData.radius_meters?.toString() || '100',
            });
        } else {
            setFormData({
                brand: 'KINGTECH',
                division_id: '',
                location_code: '',
                address: '',
                radius_meters: '100',
                device_code: '',
                device_pin: '',
            });
        }
        setError('');
    }, [initialData, isOpen]);

    const fetchDivisions = async () => {
        setFetchingDivisions(true);
        try {
            const response = await apiClient.get('/divisions');
            setDivisions(response.data.data || response.data);
        } catch (err) {
            console.error('Failed to fetch divisions', err);
        } finally {
            setFetchingDivisions(false);
        }
    };

    const handleSubmit = async () => {
        setLoading(true);
        setError('');

        const formDataToSubmit = {
            name: `${formData.brand}-${formData.location_code}`.toUpperCase(),
            code: formData.location_code.toUpperCase(),
            type: 'branch',
            division_id: formData.division_id ? parseInt(formData.division_id) : null,
            address: formData.address || null,
            radius_meters: parseInt(formData.radius_meters),
            device_code: formData.device_code || undefined,
            device_pin: formData.device_pin || undefined,
        };

        try {
            if (initialData) {
                await apiClient.put(`/organizations/${initialData.id}`, formDataToSubmit);
            } else {
                await apiClient.post('/organizations', formDataToSubmit);
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

    return (
        <Modal 
            isOpen={isOpen} 
            onClose={onClose}
            size="2xl"
            scrollBehavior="inside"
            classNames={{
                base: "rounded-[2rem] bg-white",
                header: "border-b border-slate-50 px-8 py-6",
                body: "p-8",
                footer: "border-t border-slate-50 px-8 py-6"
            }}
        >
            <ModalContent>
                {(onClose) => (
                    <>
                        <ModalHeader className="flex flex-col gap-1">
                            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-indigo-50 text-indigo-600 text-[10px] font-black uppercase tracking-[0.2em] w-max mb-2">
                                <Target className="w-3 h-3" />
                                Outlet Configuration
                            </div>
                            <h2 className="text-3xl font-black text-slate-900 tracking-tight">
                                {initialData ? 'Edit' : 'Setup'} <span className="text-indigo-600">Location</span>
                            </h2>
                            <p className="text-slate-400 text-sm font-medium">Configure operational branch parameters</p>
                        </ModalHeader>
                        
                        <ModalBody>
                            <div className="space-y-6">
                                {error && (
                                    <div className="p-4 bg-rose-50 border border-rose-100 rounded-2xl flex items-start gap-3">
                                        <p className="text-xs font-bold text-rose-700 leading-relaxed">{error}</p>
                                    </div>
                                )}

                                <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
                                    <Input 
                                        label="Brand Identity"
                                        placeholder="e.g. KINGTECH"
                                        labelPlacement="outside"
                                        startContent={<Globe className="w-4 h-4 text-default-400" />}
                                        value={formData.brand}
                                        onChange={(e) => setFormData({ ...formData, brand: e.target.value })}
                                        classNames={{
                                            label: "text-xs font-black text-slate-500 uppercase tracking-widest",
                                            inputWrapper: "h-14 bg-slate-50 border-2 border-transparent focus-within:!bg-white focus-within:!border-indigo-100 rounded-[1.25rem] shadow-none"
                                        }}
                                    />
                                    
                                    <Select 
                                        label="Division Connection"
                                        placeholder="Select Division"
                                        labelPlacement="outside"
                                        startContent={<Building className="w-4 h-4 text-default-400" />}
                                        selectedKeys={formData.division_id ? [formData.division_id] : []}
                                        onChange={(e) => setFormData({ ...formData, division_id: e.target.value })}
                                        isLoading={fetchingDivisions}
                                        classNames={{
                                            label: "text-xs font-black text-slate-500 uppercase tracking-widest",
                                            trigger: "h-14 bg-slate-50 border-2 border-transparent focus-within:!bg-white focus-within:!border-indigo-100 rounded-[1.25rem] shadow-none"
                                        }}
                                    >
                                        {divisions.map((div) => (
                                            <SelectItem key={div.id.toString()} value={div.id.toString()}>
                                                {div.name}
                                            </SelectItem>
                                        ))}
                                    </Select>
                                </div>

                                <div className="space-y-2">
                                    <div className="flex justify-between items-center">
                                        <label className="text-xs font-black text-slate-500 uppercase tracking-widest">Manual Location Code</label>
                                        <span className="text-indigo-500 font-black text-xs">PREVIEW: {formData.brand || 'BRAND'}-{formData.location_code || 'CODE'}</span>
                                    </div>
                                    <Input 
                                        placeholder="e.g. T3F-CGK"
                                        startContent={<Navigation className="w-4 h-4 text-default-400" />}
                                        value={formData.location_code}
                                        onChange={(e) => setFormData({ ...formData, location_code: e.target.value })}
                                        classNames={{
                                            input: "uppercase font-black tracking-widest",
                                            inputWrapper: "h-14 bg-slate-50 border-2 border-transparent focus-within:!bg-white focus-within:!border-indigo-100 rounded-[1.25rem] shadow-none"
                                        }}
                                    />
                                </div>

                                <div className="p-6 rounded-[2rem] bg-indigo-50/30 border border-indigo-100/50">
                                    <div className="flex items-center gap-2 text-indigo-600 font-black text-[10px] uppercase tracking-tighter mb-4">
                                        <Target className="w-3.5 h-3.5" />
                                        Radius Pengawasan
                                    </div>
                                    <Input 
                                        type="number"
                                        placeholder="Radius in meters"
                                        endContent={<span className="text-[10px] font-black text-indigo-300">METERS</span>}
                                        value={formData.radius_meters}
                                        onChange={(e) => setFormData({ ...formData, radius_meters: e.target.value })}
                                        classNames={{
                                            input: "font-black text-indigo-600",
                                            inputWrapper: "h-12 bg-white/80 backdrop-blur-sm border border-indigo-100 rounded-xl shadow-none"
                                        }}
                                    />
                                </div>

                                {!initialData && (
                                    <div className="p-6 rounded-[2rem] bg-slate-50/50 border border-slate-100">
                                        <div className="flex items-center gap-2 text-slate-700 font-black text-[10px] uppercase tracking-tighter mb-4">
                                            <MonitorSmartphone className="w-3.5 h-3.5 text-indigo-500" />
                                            Setup Mesin Absensi Awal (Opsional)
                                        </div>
                                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                                            <Input 
                                                placeholder="ID Perangkat (Auto jika kosong)"
                                                startContent={<MonitorSmartphone className="w-4 h-4 text-default-400" />}
                                                value={formData.device_code}
                                                onChange={(e) => setFormData({ ...formData, device_code: e.target.value })}
                                                classNames={{
                                                    inputWrapper: "h-12 bg-white border border-slate-200 focus-within:!border-indigo-400 rounded-xl shadow-sm"
                                                }}
                                            />
                                            <Input 
                                                type="number"
                                                maxLength={6}
                                                placeholder="PIN Mesin (6 Digit)"
                                                startContent={<Lock className="w-4 h-4 text-default-400" />}
                                                value={formData.device_pin}
                                                onChange={(e) => setFormData({ ...formData, device_pin: e.target.value })}
                                                classNames={{
                                                    inputWrapper: "h-12 bg-white border border-slate-200 focus-within:!border-indigo-400 rounded-xl shadow-sm"
                                                }}
                                            />
                                        </div>
                                    </div>
                                )}

                                <Textarea 
                                    label="Office Physical Address"
                                    placeholder="Enter complete physical address details..."
                                    labelPlacement="outside"
                                    value={formData.address}
                                    onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                                    minRows={3}
                                    classNames={{
                                        label: "text-xs font-black text-slate-500 uppercase tracking-widest",
                                        inputWrapper: "bg-slate-50 border-2 border-transparent focus-within:!bg-white focus-within:!border-indigo-100 rounded-[1.5rem] shadow-none py-4 px-5"
                                    }}
                                />
                            </div>
                        </ModalBody>

                        <ModalFooter className="flex-col sm:flex-row gap-4 pt-4">
                            <Button 
                                variant="flat"
                                onPress={onClose}
                                className="order-2 sm:order-1 flex-1 h-14 bg-slate-50 text-slate-500 font-black rounded-2xl hover:bg-slate-100 text-xs tracking-widest uppercase"
                            >
                                Cancel
                            </Button>
                            <Button 
                                isLoading={loading}
                                onPress={handleSubmit}
                                startContent={!loading && <Check className="w-5 h-5" strokeWidth={3} />}
                                className="order-1 sm:order-2 flex-[2] h-14 bg-indigo-600 text-white font-black rounded-2xl shadow-xl shadow-indigo-200 hover:bg-indigo-700 hover:-translate-y-1 transition-all text-xs tracking-widest uppercase"
                            >
                                Save Configuration
                            </Button>
                        </ModalFooter>
                    </>
                )}
            </ModalContent>
        </Modal>
    );
}
