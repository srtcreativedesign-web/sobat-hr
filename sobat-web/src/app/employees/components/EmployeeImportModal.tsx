import React from 'react';

interface EmployeeImportModalProps {
  isOpen: boolean;
  onClose: () => void;
  importFile: File | null;
  setImportFile: (file: File | null) => void;
  uploading: boolean;
  onSubmit: (e: React.FormEvent) => Promise<void>;
}

export default function EmployeeImportModal({
  isOpen,
  onClose,
  importFile,
  setImportFile,
  uploading,
  onSubmit
}: EmployeeImportModalProps) {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-xl max-w-md w-full p-6">
        <h3 className="text-xl font-bold text-gray-900 mb-4">Import Master Data Karyawan</h3>
        <p className="text-sm text-gray-600 mb-4">
          Upload file Excel (.xlsx) berisi data master karyawan.
          Pastikan ada kolom: <b>Nama, NIK, Divisi, Jabatan, No HP</b>.
        </p>

        <form onSubmit={onSubmit}>
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-700 mb-2">File Excel</label>
            <input
              type="file"
              accept=".xlsx, .xls"
              onChange={(e) => setImportFile(e.target.files ? e.target.files[0] : null)}
              className="w-full border border-gray-300 rounded-lg p-2"
              required
            />
          </div>

          <div className="flex justify-end gap-2 mt-6">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-gray-600 hover:text-gray-800"
              disabled={uploading}
            >
              Batal
            </button>
            <button
              type="submit"
              disabled={!importFile || uploading}
              className="px-4 py-2 bg-[#419cc3] text-[#89b4e1] rounded-lg hover:bg-[#2d1e24] disabled:opacity-50 flex items-center gap-2"
            >
              {uploading ? (
                <>
                  <div className="w-4 h-4 border-2 border-[#89b4e1] border-t-transparent rounded-full animate-spin"></div>
                  Memproses...
                </>
              ) : 'Upload & Import'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
