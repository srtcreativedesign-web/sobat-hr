import React, { useState } from 'react';
import { Save, Loader2, Smartphone } from 'lucide-react';
import apiClient from '@/lib/api-client';
import { Modal, ModalContent, ModalHeader, ModalBody, ModalFooter, Button, Input } from "@nextui-org/react";

interface Props {
  organizationId: number;
  onSuccess: () => void;
  onClose: () => void;
}

export default function OutletDeviceForm({ organizationId, onSuccess, onClose }: Props) {
  const [deviceName, setDeviceName] = useState('');
  const [pin, setPin] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async () => {
    if (!deviceName.trim()) return;

    setLoading(true);
    setError('');
    
    try {
        await apiClient.post('/outlet-devices', {
            organization_id: organizationId,
            device_name: deviceName,
            pin: pin,
        });
        onSuccess();
    } catch (err: any) {
        setError(err.response?.data?.message || 'Terjadi kesalahan saat menyimpan perangkat.');
        setLoading(false);
    }
  };

  return (
    <Modal 
        isOpen={true} 
        onClose={onClose}
        placement="center"
        classNames={{
            base: "rounded-[2rem]",
            header: "border-b border-slate-100 px-6 py-5",
            body: "p-6",
            footer: "border-t border-slate-100 p-4"
        }}
    >
        <ModalContent>
            {(onClose) => (
                <>
                    <ModalHeader className="flex flex-col gap-1">
                        <div className="flex items-center gap-3">
                            <div className="p-2.5 bg-indigo-50 text-indigo-600 rounded-xl">
                                <Smartphone className="w-5 h-5" />
                            </div>
                            <h3 className="text-xl font-black text-slate-800">Tambah Perangkat Manual</h3>
                        </div>
                    </ModalHeader>
                    
                    <ModalBody>
                        <p className="text-sm text-slate-500 font-medium mb-2">
                            Masukkan nama perangkat (misal: Tablet Kasir Depan) untuk men-generate Master QR.
                        </p>
                        
                        <Input
                            autoFocus
                            label="Nama Perangkat"
                            placeholder="Ketik nama perangkat..."
                            variant="bordered"
                            value={deviceName}
                            onChange={(e) => setDeviceName(e.target.value)}
                            isInvalid={!!error}
                            errorMessage={error}
                            classNames={{
                                inputWrapper: "border-slate-200 focus-within:!border-indigo-500",
                                label: "font-bold text-slate-700"
                            }}
                        />
                        <div className="mt-4">
                            <Input
                                label="PIN Perangkat (6 Digit)"
                                placeholder="Masukkan 6 angka PIN..."
                                variant="bordered"
                                value={pin}
                                maxLength={6}
                                type="number"
                                onChange={(e) => setPin(e.target.value)}
                                classNames={{
                                    inputWrapper: "border-slate-200 focus-within:!border-indigo-500",
                                    label: "font-bold text-slate-700"
                                }}
                                onKeyDown={(e) => {
                                    if (e.key === 'Enter') handleSubmit();
                                }}
                            />
                        </div>
                    </ModalBody>

                    <ModalFooter>
                        <Button color="danger" variant="light" onPress={onClose} className="font-bold">
                            Batal
                        </Button>
                        <Button 
                            color="primary" 
                            onPress={handleSubmit}
                            isLoading={loading}
                            isDisabled={!deviceName.trim() || pin.length !== 6}
                            className="font-bold shadow-md shadow-primary/20"
                            startContent={!loading && <Save className="w-4 h-4" />}
                        >
                            Simpan Perangkat
                        </Button>
                    </ModalFooter>
                </>
            )}
        </ModalContent>
    </Modal>
  );
}
