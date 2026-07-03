import React from 'react';
import { OutletDevice } from '@/types';
import { Trash2, RefreshCw, QrCode, Smartphone } from 'lucide-react';
import { format } from 'date-fns';
import { 
  Table, TableHeader, TableColumn, TableBody, TableRow, TableCell,
  Chip, Button, Tooltip, Spinner
} from "@nextui-org/react";

interface Props {
  devices: OutletDevice[];
  loading?: boolean;
  onDelete: (id: number) => void;
  onResetToken: (id: number) => void;
  onViewDetail: (device: OutletDevice) => void;
}

export default function OutletDeviceList({ devices, loading = false, onDelete, onResetToken, onViewDetail }: Props) {

  return (
    <div className="overflow-hidden border border-slate-100 rounded-2xl bg-white">
        <Table 
            aria-label="Daftar Perangkat"
            removeWrapper
            classNames={{
                th: "bg-slate-50/80 text-slate-400 font-black uppercase tracking-wider py-4 text-[10px]",
                td: "py-3 border-b border-slate-50/80 cursor-pointer",
                tr: "hover:bg-slate-50/50 transition-colors"
            }}
            selectionMode="single"
            onRowAction={(key) => {
                const device = devices.find(d => d.id.toString() === key.toString());
                if (device) onViewDetail(device);
            }}
        >
            <TableHeader>
                <TableColumn>PERANGKAT</TableColumn>
                <TableColumn>STATUS</TableColumn>
                <TableColumn>TERAKHIR AKTIF</TableColumn>
                <TableColumn align="end">AKSI</TableColumn>
            </TableHeader>
            <TableBody 
                items={devices}
                isLoading={loading}
                loadingContent={<Spinner color="primary" />}
                emptyContent={!loading && (
                    <div className="py-8 flex flex-col items-center">
                        <Smartphone className="w-10 h-10 text-slate-200 mb-2" />
                        <span className="text-slate-400 font-medium text-sm">Belum ada perangkat terdaftar</span>
                    </div>
                )}
            >
                {(device) => (
                    <TableRow key={device.id.toString()}>
                        <TableCell>
                            <div className="font-bold text-slate-800 text-sm">{device.device_name}</div>
                            {device.hardware_model ? (
                                <div className="text-[11px] font-medium text-indigo-600 mt-1 flex items-center gap-1">
                                    <Smartphone className="w-3 h-3" />
                                    Terikat pada: {device.hardware_model}
                                </div>
                            ) : (
                                <div className="text-[11px] font-medium text-slate-400 mt-1">
                                    Belum terikat ke perangkat apapun
                                </div>
                            )}
                        </TableCell>
                        <TableCell>
                            {device.status === 'active' ? (
                                <Chip size="sm" color="success" variant="flat" classNames={{base: "h-6", content: "font-black text-[9px] uppercase tracking-wider"}}>Active</Chip>
                            ) : device.status === 'pending' ? (
                                <Chip size="sm" color="warning" variant="flat" classNames={{base: "h-6", content: "font-black text-[9px] uppercase tracking-wider"}}>Pending Pair</Chip>
                            ) : (
                                <Chip size="sm" color="danger" variant="flat" classNames={{base: "h-6", content: "font-black text-[9px] uppercase tracking-wider"}}>Revoked</Chip>
                            )}
                        </TableCell>
                        <TableCell>
                            <span className="text-xs font-bold text-slate-500">
                                {device.last_active_at ? format(new Date(device.last_active_at), 'dd MMM yyyy, HH:mm') : '-'}
                            </span>
                        </TableCell>
                        <TableCell>
                            <div className="flex items-center justify-end gap-1">
                                <Button size="sm" color="primary" variant="flat" className="font-bold text-[10px]" onPress={() => onViewDetail(device)}>
                                    DETAIL
                                </Button>
                            </div>
                        </TableCell>
                    </TableRow>
                )}
            </TableBody>
        </Table>
    </div>
  );
}
