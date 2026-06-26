import React, { useRef, useState } from 'react';
import SignatureCanvas from 'react-signature-canvas';

interface SignatureModalProps {
    show: boolean;
    onClose: () => void;
    isBulkApproval: boolean;
    selectedIdsLength: number;
    onApprove: (signatureData: string, signerName: string, notes: string) => Promise<void>;
}

export default function SignatureModal({
    show,
    onClose,
    isBulkApproval,
    selectedIdsLength,
    onApprove
}: SignatureModalProps) {
    const [signerName, setSignerName] = useState('');
    const [approvalNotes, setApprovalNotes] = useState('');
    const [loading, setLoading] = useState(false);
    const sigPad = useRef<SignatureCanvas>(null);

    if (!show) return null;

    const clearSignature = () => {
        sigPad.current?.clear();
    };

    const handleConfirm = async () => {
        if (sigPad.current?.isEmpty()) {
            alert('Harap tanda tangan terlebih dahulu');
            return;
        }

        const signatureData = sigPad.current?.getCanvas().toDataURL('image/png');
        if (!signatureData) return;

        try {
            setLoading(true);
            await onApprove(signatureData, signerName, approvalNotes);
            // Form is reset via parent destroying the modal or keeping state
            setSignerName('');
            setApprovalNotes('');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-[60] p-4 text-black">
            <div className="bg-white rounded-2xl shadow-xl w-full max-w-md p-6">
                <div className="flex justify-between items-center mb-4">
                    <h3 className="text-xl font-bold text-gray-900">Tanda Tangan Approval</h3>
                    <button onClick={onClose} className="text-gray-400 hover:text-gray-600">
                        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                        </svg>
                    </button>
                </div>

                <p className="text-sm text-gray-500 mb-4">
                    Silakan tanda tangan di bawah ini untuk menyetujui payroll {isBulkApproval ? `(${selectedIdsLength} items)` : ''}.
                </p>

                <div className="mb-4">
                    <label className="block text-sm font-medium text-gray-700 mb-1">Nama Penanda Tangan</label>
                    <input
                        type="text"
                        value={signerName}
                        onChange={(e) => setSignerName(e.target.value)}
                        placeholder="Masukkan nama lengkap (e.g. Budi Santoso, HRD)"
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#93C5FD]"
                    />
                </div>

                <div className="mb-4">
                    <label className="block text-sm font-medium text-gray-700 mb-1">Catatan / Notes (Opsional)</label>
                    <textarea
                        value={approvalNotes}
                        onChange={(e) => setApprovalNotes(e.target.value)}
                        placeholder="Masukkan catatan tambahan untuk payslip ini..."
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#93C5FD]"
                        rows={2}
                    />
                </div>

                <div className="border-2 border-dashed border-gray-300 rounded-xl mb-4 bg-gray-50">
                    <SignatureCanvas
                        ref={sigPad}
                        penColor="black"
                        canvasProps={{
                            className: 'w-full h-48 rounded-xl cursor-crosshair'
                        }}
                    />
                </div>

                <div className="flex gap-3">
                    <button
                        onClick={clearSignature}
                        className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-xl font-medium hover:bg-gray-50 transition-colors"
                    >
                        Hapus
                    </button>
                    <button
                        onClick={handleConfirm}
                        disabled={loading}
                        className="flex-1 px-4 py-2 bg-[#419cc3] text-white rounded-xl font-bold hover:bg-[#5e3d4a] transition-colors disabled:opacity-50"
                    >
                        {loading ? 'Processing...' : 'Approve & Sign'}
                    </button>
                </div>
            </div>
        </div>
    );
}
