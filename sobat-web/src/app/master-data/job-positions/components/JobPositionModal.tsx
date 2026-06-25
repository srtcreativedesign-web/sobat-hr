import React, { useState, useEffect } from 'react';

export interface Division {
    id: number;
    name: string;
    department?: {
        id: number;
        name: string;
    };
}

export interface JobPositionPayload {
    name: string;
    code: string;
    division_id: string;
    level: number;
    track: string;
}

interface JobPositionModalProps {
    isOpen: boolean;
    onClose: () => void;
    onSubmit: (payload: JobPositionPayload, editingId: number | null) => void;
    isSaving: boolean;
    initialData?: JobPositionPayload | null;
    editingId: number | null;
    divisions: Division[];
}

const officeLevels = [
    { value: 0, label: 'Staff' },
    { value: 1, label: 'Supervisor (SPV)' },
    { value: 2, label: 'Manager' },
    { value: 3, label: 'General Manager (GM)' },
    { value: 4, label: 'Director' },
];

const operationalLevels = [
    { value: 0, label: 'Crew' },
    { value: 1, label: 'Supervisor' },
    { value: 2, label: 'Manager' },
];

const tracks = [
    { value: 'office', label: 'Office' },
    { value: 'operational', label: 'Operational' },
];

export default function JobPositionModal({
    isOpen,
    onClose,
    onSubmit,
    isSaving,
    initialData,
    editingId,
    divisions
}: JobPositionModalProps) {
    const [formData, setFormData] = useState<JobPositionPayload>({
        name: '',
        code: '',
        division_id: '',
        level: 0,
        track: 'office'
    });

    useEffect(() => {
        if (isOpen) {
            if (initialData) {
                setFormData(initialData);
            } else {
                setFormData({
                    name: '',
                    code: '',
                    division_id: '',
                    level: 0,
                    track: 'office'
                });
            }
        }
    }, [isOpen, initialData]);

    if (!isOpen) return null;

    const currentLevels = formData.track === 'operational' ? operationalLevels : officeLevels;

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        onSubmit(formData, editingId);
    };

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black bg-opacity-50">
            <div className="bg-white rounded-xl shadow-xl w-full max-w-lg overflow-hidden">
                <div className="px-6 py-4 border-b border-gray-100 flex justify-between items-center">
                    <h3 className="text-lg font-semibold text-gray-900">
                        {editingId ? 'Edit Jabatan' : 'Tambah Jabatan'}
                    </h3>
                    <button onClick={onClose} className="text-gray-400 hover:text-gray-600">
                        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                        </svg>
                    </button>
                </div>

                <form onSubmit={handleSubmit} className="p-6 space-y-4">
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Nama Jabatan <span className="text-red-500">*</span></label>
                        <input
                            type="text"
                            required
                            className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition-all"
                            value={formData.name}
                            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                            placeholder="Contoh: Senior Backend Developer"
                        />
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">Kode</label>
                            <input
                                type="text"
                                className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition-all"
                                value={formData.code}
                                onChange={(e) => setFormData({ ...formData, code: e.target.value })}
                                placeholder="Contoh: DEV-SR"
                            />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">Level Approval <span className="text-red-500">*</span></label>
                            <select
                                className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition-all"
                                value={formData.level}
                                onChange={(e) => setFormData({ ...formData, level: parseInt(e.target.value) })}
                            >
                                {currentLevels.map(l => (
                                    <option key={l.value} value={l.value}>{l.label}</option>
                                ))}
                            </select>
                        </div>
                    </div>

                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Track (Office / Operational) <span className="text-red-500">*</span></label>
                        <div className="flex gap-4 mt-2">
                            {tracks.map(t => (
                                <label key={t.value} className="flex items-center gap-2 cursor-pointer">
                                    <input
                                        type="radio"
                                        name="track"
                                        value={t.value}
                                        checked={formData.track === t.value}
                                        onChange={(e) => setFormData({ ...formData, track: e.target.value })}
                                        className="w-4 h-4 text-blue-600 focus:ring-blue-500 border-gray-300"
                                    />
                                    <span className="text-sm text-gray-700">{t.label}</span>
                                </label>
                            ))}
                        </div>
                    </div>

                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Divisi</label>
                        <select
                            className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition-all"
                            value={formData.division_id}
                            onChange={(e) => setFormData({ ...formData, division_id: e.target.value })}
                        >
                            <option value="">-- Pilih Divisi --</option>
                            {divisions.map(div => (
                                <option key={div.id} value={div.id}>
                                    {div.name} {div.department ? `(${div.department.name})` : ''}
                                </option>
                            ))}
                        </select>
                    </div>

                    <div className="pt-4 flex justify-end gap-3">
                        <button
                            type="button"
                            onClick={onClose}
                            className="px-4 py-2 text-gray-700 hover:bg-gray-100 rounded-lg transition-colors"
                        >
                            Batal
                        </button>
                        <button
                            type="submit"
                            disabled={isSaving}
                            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
                        >
                            {isSaving && (
                                <svg className="animate-spin h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                                </svg>
                            )}
                            {isSaving ? 'Menyimpan...' : 'Simpan'}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
}
