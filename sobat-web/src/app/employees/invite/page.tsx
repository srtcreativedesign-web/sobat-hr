'use client';

import { useState } from 'react';
import apiClient from '@/lib/api-client';
import DashboardLayout from '@/components/DashboardLayout';

interface PreviewRow {
  rowIndex: number;
  name: string;
  email: string;
  valid: boolean;
  errors: string[];
  temporary_password: string | null;
}

export default function InviteStaffPage() {
  const [file, setFile] = useState<File | null>(null);
  const [preview, setPreview] = useState<PreviewRow[]>([]);
  const [selectedRows, setSelectedRows] = useState<Set<number>>(new Set());
  const [loading, setLoading] = useState(false);
  const [uploading, setUploading] = useState(false);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFile = e.target.files?.[0];
    if (selectedFile) {
      setFile(selectedFile);
    }
  };

  const handleUpload = async () => {
    if (!file) return;

    setUploading(true);
    const formData = new FormData();
    formData.append('file', file);

    try {
      // apiClient automatically handles Authorization header
      const response = await apiClient.post('/staff/import', formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
        timeout: 120000, // 2 minutes timeout
      });

      const data = response.data;
      setPreview(data.preview || []);
    } catch (error: any) {
      console.error('Upload Error:', error);
      alert(error.response?.data?.error || error.message || 'Upload failed');
    } finally {
      setUploading(false);
      setFile(null);
    }
  };

  const handleSelectRow = (rowIndex: number) => {
    const newSelected = new Set(selectedRows);
    if (newSelected.has(rowIndex)) {
      newSelected.delete(rowIndex);
    } else {
      newSelected.add(rowIndex);
    }
    setSelectedRows(newSelected);
  };

  const handleSelectAll = () => {
    const validRows = preview.filter(row => row.valid);
    if (selectedRows.size === validRows.length && validRows.length > 0) {
      setSelectedRows(new Set());
    } else {
      setSelectedRows(new Set(validRows.map(row => row.rowIndex)));
    }
  };

  const handleInvite = async () => {
    if (selectedRows.size === 0) return;

    setLoading(true);
    const selectedData = preview.filter(row => selectedRows.has(row.rowIndex));

    try {
      const response = await apiClient.post('/staff/invite/execute', {
        rows: selectedData
      });

      const result = response.data;

      let message = result.message;
      if (result.failed > 0) {
        message += `\n(${result.failed} failed to invite)`;
      }

      alert(message);

      // Successfully invited, clear preview
      setPreview([]);
      setSelectedRows(new Set());
      setFile(null);

    } catch (error: any) {
      console.error('Invite error:', error);
      alert(error.response?.data?.message || 'Invite failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <DashboardLayout>
      {/* Header */}
      <div className="bg-white/80 backdrop-blur-md border-b border-gray-100 sticky top-0 z-20">
        <div className="px-8 py-6">
          <h1 className="text-3xl font-bold bg-gradient-to-r from-[#1A4D2E] to-[#49FFB8] bg-clip-text text-transparent">
            Invite Staff
          </h1>
          <p className="text-gray-500 mt-1">Upload Excel file to bulk invite new staff members.</p>
        </div>
      </div>

      <div className="p-8 space-y-8 animate-fade-in-up">
        {/* Upload Card */}
        <div className="glass-card p-8 relative overflow-hidden">
          <div className="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-[#1A4D2E] to-[#49FFB8] opacity-10 rounded-bl-full pointer-events-none"></div>

          <h2 className="text-xl font-bold text-gray-800 mb-6 flex items-center gap-2">
            <div className="w-10 h-10 rounded-lg bg-[#1A4D2E]/10 flex items-center justify-center text-[#1A4D2E]">
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12" /></svg>
            </div>
            Upload Excel File
          </h2>

          <div className="border-2 border-dashed border-gray-300 rounded-2xl p-8 hover:border-[#1A4D2E] hover:bg-[#1A4D2E]/5 transition-all text-center">
            <input
              type="file"
              id="file-upload"
              accept=".xlsx,.xls"
              onChange={handleFileChange}
              className="hidden"
            />
            <label htmlFor="file-upload" className="cursor-pointer flex flex-col items-center">
              <div className="w-16 h-16 rounded-full bg-green-100 text-[#1A4D2E] flex items-center justify-center mb-4">
                <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" /></svg>
              </div>
              {file ? (
                <p className="text-lg font-semibold text-[#1A4D2E]">{file.name}</p>
              ) : (
                <>
                  <p className="text-lg font-medium text-gray-600">Click to upload file</p>
                  <p className="text-sm text-gray-400 mt-1">Supports .xlsx and .xls</p>
                </>
              )}
            </label>
          </div>

          <div className="mt-6 flex justify-end">
            <button
              onClick={handleUpload}
              disabled={!file || uploading}
              className="px-8 py-3 bg-gradient-to-r from-[#1A4D2E] to-[#2d7a4a] text-white font-bold rounded-xl shadow-lg hover:shadow-[#1A4D2E]/20 hover:scale-[1.02] active:scale-[0.98] transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
            >
              {uploading ? (
                <>
                  <svg className="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle><path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                  Processing...
                </>
              ) : (
                'Upload & Preview'
              )}
            </button>
          </div>
        </div>

        {/* Preview Section */}
        {preview.length > 0 && (
          <div className="glass-card p-8 animate-fade-in-up">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-xl font-bold text-gray-800">Review Data</h2>
              <div className="flex gap-4">
                <button
                  onClick={handleSelectAll}
                  className="px-4 py-2 text-[#1A4D2E] font-semibold hover:bg-green-50 rounded-lg transition-colors"
                >
                  Select All Valid
                </button>
                <button
                  onClick={handleInvite}
                  disabled={selectedRows.size === 0 || loading}
                  className="px-6 py-2 bg-[#1A4D2E] text-white font-semibold rounded-lg hover:bg-[#143d24] transition-colors disabled:opacity-50"
                >
                  {loading ? 'Sending Invites...' : `Invite Selected (${selectedRows.size})`}
                </button>
              </div>
            </div>

            <div className="overflow-x-auto border border-gray-100 rounded-xl">
              <table className="w-full">
                <thead className="bg-gray-50/50">
                  <tr>
                    <th className="px-6 py-4 text-left">
                      <input
                        type="checkbox"
                        onChange={handleSelectAll}
                        checked={selectedRows.size === preview.filter(r => r.valid).length && preview.length > 0}
                        className="rounded border-gray-300 text-[#1A4D2E] focus:ring-[#1A4D2E]"
                      />
                    </th>
                    <th className="px-6 py-4 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">Name</th>
                    <th className="px-6 py-4 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">Email</th>
                    <th className="px-6 py-4 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">Temp Password</th>
                    <th className="px-6 py-4 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">Status</th>
                    <th className="px-6 py-4 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">Issues</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {preview.map((row) => (
                    <tr key={row.rowIndex} className={`hover:bg-gray-50/50 transition-colors ${!row.valid ? 'bg-red-50/30' : ''}`}>
                      <td className="px-6 py-4">
                        {row.valid && (
                          <input
                            type="checkbox"
                            checked={selectedRows.has(row.rowIndex)}
                            onChange={() => handleSelectRow(row.rowIndex)}
                            className="rounded border-gray-300 text-[#1A4D2E] focus:ring-[#1A4D2E]"
                          />
                        )}
                      </td>
                      <td className="px-6 py-4 text-sm font-medium text-gray-900">{row.name}</td>
                      <td className="px-6 py-4 text-sm text-gray-500">{row.email}</td>
                      <td className="px-6 py-4 text-sm font-mono text-gray-400">{row.temporary_password}</td>
                      <td className="px-6 py-4">
                        <span className={`px-3 py-1 rounded-full text-xs font-bold ${row.valid
                          ? 'bg-green-100 text-green-700'
                          : 'bg-red-100 text-red-700'
                          }`}>
                          {row.valid ? 'Valid' : 'Invalid'}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-xs text-red-500">
                        {row.errors.join(', ')}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>
    </DashboardLayout>
  );
}