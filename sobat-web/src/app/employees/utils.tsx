export const formatDate = (dateString: string | undefined) => {
  if (!dateString) return '-';
  return new Date(dateString).toLocaleDateString('id-ID', {
    day: 'numeric',
    month: 'long',
    year: 'numeric'
  });
};

export const formatCurrency = (amount: number | undefined) => {
  if (!amount) return '-';
  return new Intl.NumberFormat('id-ID', {
    style: 'currency',
    currency: 'IDR',
    minimumFractionDigits: 0
  }).format(amount);
};

export const getStatusBadge = (status: string) => {
  const styles = {
    active: 'bg-green-100 text-green-800',
    inactive: 'bg-gray-100 text-gray-800',
    resigned: 'bg-red-100 text-red-800'
  };
  return styles[status as keyof typeof styles] || styles.inactive;
};

export const getGenderLabel = (gender: string | undefined) => {
  if (gender === 'male') return 'Laki-laki';
  if (gender === 'female') return 'Perempuan';
  return '-';
};

export const formatEducation = (edu: any) => {
  if (!edu) return '-';
  if (typeof edu === 'string') return edu;
  if (typeof edu === 'object') {
    if (edu.s3) return `S3`;
    if (edu.s2) return `S2`;
    if (edu.s1) return `S1`;
    if (edu.smk) return `SMA/SMK`;
    if (edu.smp) return `SMP`;
    if (edu.sd) return `SD`;
    return '-';
  }
  return '-';
};

export const renderEducationDetails = (edu: any) => {
  if (!edu) return '-';
  if (typeof edu === 'string') return edu;
  if (typeof edu === 'object') {
    const levels = [
      { key: 's3', label: 'S3' },
      { key: 's2', label: 'S2' },
      { key: 's1', label: 'S1' },
      { key: 'smk', label: 'SMA/SMK' },
      { key: 'smp', label: 'SMP' },
      { key: 'sd', label: 'SD' },
    ];

    const filledLevels = levels.filter(l => edu[l.key]);

    if (filledLevels.length === 0) return '-';

    return (
      <div className="flex flex-col gap-1 mt-1">
        {filledLevels.map(l => (
          <div key={l.key} className="text-sm">
            <span className="font-semibold text-gray-600 mr-2">{l.label}:</span>
            <span>{edu[l.key]}</span>
          </div>
        ))}
      </div>
    );
  }
  return '-';
};

export const isExpiringSoon = (dateString: string | undefined) => {
  if (!dateString) return false;
  const end = new Date(dateString);
  const now = new Date();
  const diffTime = end.getTime() - now.getTime();
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  return diffDays <= 30 && diffDays >= 0;
};
