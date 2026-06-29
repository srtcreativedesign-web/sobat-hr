import React, { useState, useEffect } from 'react';
import { MonitorSmartphone, Plus } from 'lucide-react';
import apiClient from '@/lib/api-client';
import { Organization, OutletDevice } from '@/types';
import Swal from 'sweetalert2';
import OutletDeviceList from './OutletDeviceList';
import OutletDeviceForm from './OutletDeviceForm';
import OutletDeviceQR from './OutletDeviceQR';
import { Modal, ModalContent, ModalHeader, ModalBody, ModalFooter, Button } from "@nextui-org/react";

interface Props {
  outlet: Organization;
  onClose: () => void;
}

export default function OutletDevicesManager({ outlet, onClose }: Props) {
  const [devices, setDevices] = useState<OutletDevice[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [selectedDeviceForDetail, setSelectedDeviceForDetail] = useState<OutletDevice | null>(null);

  useEffect(() => {
    fetchDevices();
  }, [outlet.id]);

  const fetchDevices = async () => {
    setLoading(true);
    try {
      const response = await apiClient.get(`/outlet-devices?organization_id=${outlet.id}`);
      setDevices(response.data.data || response.data || []);
    } catch (err) {
      console.error(err);
      Swal.fire({
          icon: 'error',
          title: 'Gagal',
          text: 'Gagal memuat daftar perangkat',
      });
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id: number) => {
      const result = await Swal.fire({
          title: 'Hapus Perangkat?',
          text: 'Perangkat ini tidak akan bisa digunakan lagi untuk absensi.',
          icon: 'warning',
          showCancelButton: true,
          confirmButtonColor: '#ef4444',
          confirmButtonText: 'Hapus',
          cancelButtonText: 'Batal',
      });

      if (result.isConfirmed) {
          try {
              await apiClient.delete(`/outlet-devices/${id}`);
              fetchDevices();
          } catch (err) {
              Swal.fire('Error', 'Gagal menghapus perangkat', 'error');
          }
      }
  };

  const handleResetToken = async (id: number) => {
      const result = await Swal.fire({
          title: 'Reset Activation Token?',
          text: 'Token lama akan kedaluwarsa. Perangkat yang sudah dipairing harus dipairing ulang.',
          icon: 'question',
          showCancelButton: true,
          confirmButtonText: 'Reset',
      });

      if (result.isConfirmed) {
          try {
              await apiClient.post(`/outlet-devices/${id}/token`);
              fetchDevices();
              if (selectedDeviceForDetail && selectedDeviceForDetail.id === id) {
                  const res = await apiClient.get(`/outlet-devices?organization_id=${outlet.id}`);
                  const d = (res.data.data || res.data).find((x: any) => x.id === id);
                  if (d) setSelectedDeviceForDetail(d);
              }
          } catch (err) {
              Swal.fire('Error', 'Gagal mereset token', 'error');
          }
      }
  };

  return (
    <>
        <Modal 
            isOpen={true} 
            onClose={onClose}
            size="3xl"
            scrollBehavior="inside"
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
                                    <MonitorSmartphone className="w-5 h-5" />
                                </div>
                                <div>
                                    <h2 className="text-xl font-black text-slate-800 leading-tight">Manajemen Perangkat Sobat Outlet</h2>
                                    <p className="text-xs font-bold text-slate-400 mt-0.5">Outlet: <span className="text-indigo-500">{outlet.name}</span></p>
                                </div>
                            </div>
                        </ModalHeader>
                        
                        <ModalBody>
                            <div className="flex justify-between items-center mb-2">
                                <p className="text-sm text-slate-500 font-medium">Daftar perangkat yang terhubung sebagai mesin absensi.</p>
                                <Button 
                                    onPress={() => setShowForm(true)}
                                    startContent={<Plus className="w-4 h-4" />}
                                    className="bg-indigo-600 text-white font-bold shadow-md shadow-indigo-200 hover:bg-indigo-700"
                                >
                                    Tambah Manual
                                </Button>
                            </div>

                            <OutletDeviceList 
                                devices={devices} 
                                loading={loading}
                                onDelete={handleDelete} 
                                onResetToken={handleResetToken}
                                onViewDetail={setSelectedDeviceForDetail}
                            />
                        </ModalBody>
                    </>
                )}
            </ModalContent>
        </Modal>

        {showForm && (
            <OutletDeviceForm 
                organizationId={outlet.id} 
                onClose={() => setShowForm(false)} 
                onSuccess={() => {
                    setShowForm(false);
                    fetchDevices();
                }} 
            />
        )}

        {selectedDeviceForDetail && (
            <Modal 
                isOpen={true} 
                onClose={() => setSelectedDeviceForDetail(null)}
                size="md"
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
                                <h3 className="font-black text-lg text-slate-800">Detail Mesin</h3>
                                <p className="text-xs font-medium text-slate-400">Informasi detail perangkat absensi</p>
                            </ModalHeader>
                            <ModalBody>
                                <div className="space-y-4">
                                    <div className="bg-slate-50 p-4 rounded-xl border border-slate-100 flex flex-col gap-3">
                                        <div>
                                            <div className="text-[10px] font-bold text-slate-400 uppercase">Nama Perangkat</div>
                                            <div className="font-black text-slate-800">{selectedDeviceForDetail.device_name}</div>
                                        </div>
                                        <div>
                                            <div className="text-[10px] font-bold text-slate-400 uppercase">Device ID (Kode)</div>
                                            <div className="font-black text-indigo-600 font-mono">{selectedDeviceForDetail.device_code || '-'}</div>
                                        </div>
                                        <div>
                                            <div className="text-[10px] font-bold text-slate-400 uppercase">PIN Akses</div>
                                            <div className="font-black text-emerald-600 font-mono tracking-widest text-lg">{selectedDeviceForDetail.pin || '-'}</div>
                                        </div>
                                        <div>
                                            <div className="text-[10px] font-bold text-slate-400 uppercase">Status</div>
                                            <div className="font-bold text-slate-700 capitalize">{selectedDeviceForDetail.status}</div>
                                        </div>
                                    </div>

                                    <div className="grid grid-cols-2 gap-3 mt-4">
                                        <Button 
                                            variant="flat" 
                                            color="secondary" 
                                            className="font-bold text-xs w-full"
                                            onPress={() => {
                                                handleResetToken(selectedDeviceForDetail.id);
                                            }}
                                        >
                                            Unpair (Reset)
                                        </Button>
                                        <Button 
                                            variant="flat" 
                                            color="danger" 
                                            className="font-bold text-xs w-full"
                                            onPress={() => {
                                                handleDelete(selectedDeviceForDetail.id);
                                                onClose();
                                            }}
                                        >
                                            Hapus
                                        </Button>
                                    </div>
                                </div>
                            </ModalBody>
                        </>
                    )}
                </ModalContent>
            </Modal>
        )}
    </>
  );
}
