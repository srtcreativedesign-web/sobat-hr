'use client';

import React, { useState, useEffect, useRef } from 'react';
import apiClient from '@/lib/api-client';
import { Organization } from '@/types';
import { QRCodeSVG } from 'qrcode.react';
import { 
  QrCode, 
  RotateCw, 
  Printer, 
  Download, 
  CheckCircle2, 
  XCircle, 
  Loader2,
  Search,
  MapPin,
  Calendar,
  Info
} from 'lucide-react';
import Swal from 'sweetalert2';

interface QrCodeLocation {
  id: number;
  organization_id: number;
  qr_code: string;
  floor_number: number;
  location_name: string;
  is_active: boolean;
  installed_at: string;
  notes?: string;
  organization?: Organization;
}

const QrManagement = () => {
  const [outlets, setOutlets] = useState<Organization[]>([]);
  const [qrCodes, setQrCodes] = useState<QrCodeLocation[]>([]);
  const [loading, setLoading] = useState(true);
  const [processingId, setProcessingId] = useState<number | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedQr, setSelectedQr] = useState<QrCodeLocation | null>(null);
  const printRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    setLoading(true);
    try {
      const [outletsRes, qrRes] = await Promise.all([
        apiClient.get('/organizations?type=branch'), // Branch usually means outlet in this system
        apiClient.get('/attendance/qr-codes')
      ]);
      setOutlets(outletsRes.data);
      setQrCodes(qrRes.data);
    } catch (error) {
      console.error('Error fetching QR data:', error);
      Swal.fire({
        icon: 'error',
        title: 'Gagal memuat data',
        text: 'Terjadi kesalahan saat mengambil data outlet dan QR code.',
      });
    } finally {
      setLoading(false);
    }
  };

  const handleGenerate = async (outletId: number, floor: number = 1) => {
    const result = await Swal.fire({
      title: 'Konfirmasi Pembuatan QR',
      text: 'Ini akan membuat QR Code baru dan menonaktifkan yang lama jika ada. Lanjutkan?',
      icon: 'question',
      showCancelButton: true,
      confirmButtonText: 'Ya, Buat QR',
      cancelButtonText: 'Batal',
      confirmButtonColor: '#06b6d4'
    });

    if (!result.isConfirmed) return;

    setProcessingId(outletId);
    try {
      const res = await apiClient.post('/attendance/qr-codes/generate-single', {
        organization_id: outletId,
        floor_number: floor,
        location_name: `Pintu Masuk Lantai ${floor}`
      });

      if (res.data.success) {
        Swal.fire({
          icon: 'success',
          title: 'QR Code Berhasil Dibuat',
          timer: 1500,
          showConfirmButton: false
        });
        fetchData(); // Refresh data
      }
    } catch (error: any) {
      console.error('Error generating QR:', error);
      Swal.fire({
        icon: 'error',
        title: 'Gagal membuat QR Code',
        text: error.response?.data?.message || 'Terjadi kesalahan sistem.'
      });
    } finally {
      setProcessingId(null);
    }
  };

  const handlePrint = () => {
    if (!selectedQr) return;
    
    const printContent = printRef.current;
    if (!printContent) return;

    const windowPrint = window.open('', '', 'width=800,height=900');
    if (!windowPrint) return;

    windowPrint.document.write('<html><head><title>Cetak QR Code</title>');
    windowPrint.document.write('<style>');
    windowPrint.document.write(`
      @page { size: A4; margin: 0; }
      body { font-family: sans-serif; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; margin: 0; }
      .container { border: 2px solid #333; padding: 40px; border-radius: 20px; text-align: center; max-width: 80%; }
      .outlet-name { font-size: 32px; font-weight: bold; margin-bottom: 10px; text-transform: uppercase; }
      .location { font-size: 20px; color: #666; margin-bottom: 30px; }
      .qr-wrapper { margin: 20px 0; }
      .instructions { margin-top: 30px; font-size: 18px; color: #444; }
      .footer { margin-top: 40px; font-size: 14px; color: #888; border-top: 1px solid #eee; padding-top: 20px; }
      .logo { font-weight: 900; font-size: 40px; color: #06b6d4; margin-bottom: 20px; }
    `);
    windowPrint.document.write('</style></head><body>');
    windowPrint.document.write(printContent.innerHTML);
    windowPrint.document.write('</body></html>');
    windowPrint.document.close();
    windowPrint.focus();
    
    // Give time for styles to load (especially important for images/icons)
    setTimeout(() => {
      windowPrint.print();
      windowPrint.close();
    }, 500);
  };

  const filteredOutlets = outlets.filter(o => 
    o.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    o.code.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const getOutletQr = (id: number) => qrCodes.find(q => q.organization_id === id && q.is_active);

  return (
    <div className="space-y-6">
      {/* Header Info */}
      <div className="bg-gradient-to-r from-cyan-600 to-blue-600 rounded-2xl p-6 text-white flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <QrCode className="w-6 h-6" />
            <h2 className="text-2xl font-bold font-display">Manajemen QR Code</h2>
          </div>
          <p className="text-cyan-50/80 max-w-lg">
            Kelola dan perbarui QR Code absensi offline untuk setiap outlet secara berkala untuk menjaga integritas data.
          </p>
        </div>
        <button 
          onClick={fetchData}
          disabled={loading}
          className="bg-white/10 hover:bg-white/20 backdrop-blur-md px-4 py-2 rounded-xl transition-all flex items-center gap-2 border border-white/20"
        >
          <RotateCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
          Refresh Data
        </button>
      </div>

      {/* Filter & Search */}
      <div className="bg-white rounded-2xl p-4 border border-gray-100 shadow-sm flex items-center gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input 
            type="text" 
            placeholder="Cari outlet berdasarkan nama atau kode..." 
            className="w-full pl-11 pr-4 py-2 bg-gray-50 border-none rounded-xl focus:ring-2 focus:ring-cyan-500/20 transition-all outline-none text-sm"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>
      </div>

      {/* Main Table */}
      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-gray-50/50 border-b border-gray-100">
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Outlet</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Status QR</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Terakhir Diperbarui</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">QR String</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider text-right">Aksi</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {loading ? (
                Array(5).fill(0).map((_, i) => (
                  <tr key={i} className="animate-pulse">
                    <td className="px-6 py-4" colSpan={5}>
                      <div className="h-10 bg-gray-50 rounded-lg"></div>
                    </td>
                  </tr>
                ))
              ) : filteredOutlets.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-6 py-12 text-center text-gray-400">
                    <div className="flex flex-col items-center gap-2">
                      <Search className="w-8 h-8 opacity-20" />
                      <p>Tidak ada outlet yang ditemukan.</p>
                    </div>
                  </td>
                </tr>
              ) : filteredOutlets.map((outlet) => {
                const qr = getOutletQr(outlet.id);
                return (
                  <tr key={outlet.id} className="hover:bg-gray-50/50 transition-colors group">
                    <td className="px-6 py-4">
                      <div className="flex flex-col">
                        <span className="font-semibold text-gray-800">{outlet.name}</span>
                        <span className="text-xs text-gray-400">{outlet.code}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      {qr ? (
                        <div className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-600 text-xs font-medium">
                          <CheckCircle2 className="w-3.5 h-3.5" />
                          Aktif
                        </div>
                      ) : (
                        <div className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-amber-50 text-amber-600 text-xs font-medium">
                          <XCircle className="w-3.5 h-3.5" />
                          Belum Ada
                        </div>
                      )}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-2 text-sm text-gray-600">
                        <Calendar className="w-3.5 h-3.5 opacity-40" />
                        {qr ? new Date(qr.installed_at).toLocaleDateString('id-ID', {
                          day: 'numeric',
                          month: 'long',
                          year: 'numeric'
                        }) : '-'}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <code className="px-2 py-1 bg-gray-100 rounded text-[10px] font-mono text-gray-500 truncate max-w-[150px] inline-block">
                        {qr?.qr_code || '-'}
                      </code>
                    </td>
                    <td className="px-6 py-4 text-right">
                      <div className="flex items-center justify-end gap-2">
                        {qr && (
                          <button 
                            onClick={() => setSelectedQr(qr)}
                            className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors title='Tampilkan QR'"
                          >
                            <QrCode className="w-4 h-4" />
                          </button>
                        )}
                        <button 
                          onClick={() => handleGenerate(outlet.id)}
                          disabled={processingId === outlet.id}
                          className={`flex items-center gap-2 px-3 py-1.5 rounded-lg text-xs font-medium transition-all ${
                            qr 
                            ? 'text-cyan-600 hover:bg-cyan-50' 
                            : 'bg-cyan-600 text-white hover:bg-cyan-700 shadow-sm shadow-cyan-500/10'
                          }`}
                        >
                          {processingId === outlet.id ? (
                            <Loader2 className="w-3.5 h-3.5 animate-spin" />
                          ) : (
                            <RotateCw className="w-3.5 h-3.5" />
                          )}
                          {qr ? 'Perbarui' : 'Generate'}
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* QR Modal Preview */}
      {selectedQr && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-gray-900/60 backdrop-blur-sm" onClick={() => setSelectedQr(null)} />
          <div className="relative bg-white rounded-3xl w-full max-w-md overflow-hidden shadow-2xl scale-in-center">
            <div className="p-6 text-center border-b border-gray-100">
              <h3 className="text-xl font-bold flex items-center justify-center gap-2 text-gray-800">
                <QrCode className="w-5 h-5 text-cyan-600" />
                QR Code Absensi
              </h3>
              <div className="mt-2">
                <p className="text-gray-900 font-black text-lg">{selectedQr.organization?.name || 'Outlet'}</p>
                <p className="text-cyan-600 font-mono text-xs font-bold tracking-widest uppercase">{selectedQr.organization?.code}</p>
              </div>
            </div>
            
            <div className="p-10 flex flex-col items-center">
              <div className="p-4 bg-white border-4 border-gray-50 rounded-2xl shadow-inner mb-6">
                <QRCodeSVG 
                  value={selectedQr.qr_code}
                  size={200}
                  level="H"
                  includeMargin={true}
                />
              </div>
              
              <div className="bg-cyan-50 rounded-xl p-4 w-full flex items-start gap-3 mb-6">
                <Info className="w-5 h-5 text-cyan-600 shrink-0 mt-0.5" />
                <div className="text-left">
                  <p className="text-xs font-semibold text-cyan-900">Petunjuk Pemasangan:</p>
                  <p className="text-[11px] text-cyan-700 leading-relaxed mt-1">
                    Cetak QR Code ini dan tempelkan di area outlet yang terjangkau oleh CCTV. Pastikan pencahayaan cukup agar mudah discan oleh aplikasi karyawan.
                  </p>
                </div>
              </div>

              <div className="flex gap-3 w-full">
                <button 
                  onClick={() => setSelectedQr(null)}
                  className="flex-1 px-4 py-2.5 rounded-xl border border-gray-200 text-gray-600 font-medium hover:bg-gray-50 transition-all"
                >
                  Tutup
                </button>
                <button 
                  onClick={handlePrint}
                  className="flex-1 px-4 py-2.5 rounded-xl bg-cyan-600 text-white font-medium hover:bg-cyan-700 transition-all flex items-center justify-center gap-2 shadow-lg shadow-cyan-600/20"
                >
                  <Printer className="w-4 h-4" />
                  Cetak QR
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Hidden Print Content */}
      <div style={{ display: 'none' }}>
        <div ref={printRef}>
          <div className="container">
            <div className="logo">SOBAT HR</div>
            <div className="outlet-name">{selectedQr?.organization?.name}</div>
            <div className="location" style={{ fontSize: '24px', fontWeight: 'bold', color: '#06b6d4', marginBottom: '5px' }}>
              {selectedQr?.organization?.code}
            </div>
            <div className="location">{selectedQr?.location_name}</div>
            <div className="qr-wrapper">
              <QRCodeSVG 
                value={selectedQr?.qr_code || ''}
                size={400}
                level="H"
                includeMargin={true}
              />
            </div>
            <div className="instructions">
              <strong>SCAN UNTUK ABSENSI</strong><br />
              Gunakan Aplikasi Sobat Mobile (Input Offline)
            </div>
            <div className="footer">
              Dicetak pada: {new Date().toLocaleString('id-ID')}<br />
              QR ID: {selectedQr?.qr_code}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default QrManagement;
