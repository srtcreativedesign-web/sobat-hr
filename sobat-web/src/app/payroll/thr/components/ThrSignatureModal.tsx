import React, { useRef, useState, useEffect } from 'react';
import SignatureCanvas from 'react-signature-canvas';
import Swal from 'sweetalert2';

interface ThrSignatureModalProps {
    show: boolean;
    onClose: () => void;
    approvalMode: 'single' | 'bulk';
    selectedIdsLength: number;
    draftThrsLength: number;
    onApprove: (signature: string, name: string) => Promise<void>;
    loading: boolean;
}

export default function ThrSignatureModal({
    show,
    onClose,
    approvalMode,
    selectedIdsLength,
    draftThrsLength,
    onApprove,
    loading
}: ThrSignatureModalProps) {
    const sigCanvasRef = useRef<SignatureCanvas>(null);
    const [signerName, setSignerName] = useState('');

    // Reset when modal opens
    useEffect(() => {
        if (show) {
            setSignerName('');
            setTimeout(() => {
                sigCanvasRef.current?.clear();
            }, 100);
        }
    }, [show]);

    if (!show) return null;

    const handleApprove = async () => {
        if (!signerName.trim()) {
            Swal.fire('Perhatian', 'Nama penandatangan harus diisi', 'warning');
            return;
        }

        if (sigCanvasRef.current?.isEmpty()) {
            Swal.fire('Perhatian', 'Tanda tangan harus diisi', 'warning');
            return;
        }

        const signature = sigCanvasRef.current?.toDataURL('image/png') || '';
        await onApprove(signature, signerName);
    };

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
            <div className="bg-white rounded-2xl shadow-2xl w-full max-w-lg overflow-hidden animate-in fade-in zoom-in duration-200">
                <div className="p-6 border-b border-gray-100 bg-gradient-to-r from-green-500 to-emerald-600">
                    <h2 className="text-xl font-bold text-white flex items-center gap-2">
                        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                        {approvalMode === 'single' ? 'Approve THR' : `Bulk Approve THR`}
                    </h2>
                    <p className="text-green-100 text-sm mt-1">
                        {approvalMode === 'single'
                            ? 'Tandatangani untuk menyetujui slip THR ini'
                            : `Tandatangani untuk menyetujui ${selectedIdsLength > 0 ? selectedIdsLength : draftThrsLength} slip THR`
                        }
                    </p>
                </div>

                <div className="p-6 space-y-6">
                    {/* Signer Name */}
                    <div>
                        <label className="block text-sm font-bold text-gray-700 mb-2">Nama Penandatangan</label>
                        <input
                            type="text"
                            value={signerName}
                            onChange={(e) => setSignerName(e.target.value)}
                            placeholder="Masukkan nama lengkap..."
                            className="w-full px-4 py-3 border-2 border-gray-200 rounded-xl focus:outline-none focus:border-green-500 text-sm font-medium transition-colors"
                        />
                    </div>

                    {/* Signature Pad */}
                    <div>
                        <div className="flex items-center justify-between mb-2">
                            <label className="block text-sm font-bold text-gray-700">Tanda Tangan Digital</label>
                            <button
                                onClick={() => sigCanvasRef.current?.clear()}
                                className="text-xs text-red-500 font-bold hover:underline"
                            >
                                Hapus
                            </button>
                        </div>
                        <div className="border-2 border-dashed border-gray-300 rounded-xl overflow-hidden bg-gray-50 relative">
                            <SignatureCanvas
                                ref={sigCanvasRef}
                                penColor="#1a1a2e"
                                canvasProps={{
                                    width: 440,
                                    height: 200,
                                    className: 'w-full bg-white cursor-crosshair',
                                    style: { width: '100%', height: '200px' },
                                }}
                            />
                            <div className="absolute bottom-3 left-1/2 -translate-x-1/2 text-xs text-gray-300 font-medium pointer-events-none">
                                Tanda tangan di sini
                            </div>
                        </div>
                    </div>
                </div>

                <div className="p-6 bg-gray-50 border-t border-gray-100 flex justify-end gap-3">
                    <button
                        onClick={onClose}
                        className="px-6 py-3 text-gray-500 font-bold hover:bg-gray-100 rounded-xl transition-all"
                    >
                        Batal
                    </button>
                    <button
                        onClick={handleApprove}
                        disabled={loading}
                        className="px-8 py-3 bg-green-500 text-white rounded-xl font-bold hover:bg-green-600 transition-all flex items-center gap-2 shadow-lg shadow-green-100 disabled:opacity-50"
                    >
                        {loading && <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24"><circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle><path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>}
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                        </svg>
                        Approve & Tandatangan
                    </button>
                </div>
            </div>
        </div>
    );
}
