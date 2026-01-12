<?php

namespace App\Repositories;

use App\Models\Payroll;
use App\Models\Employee;
use Carbon\Carbon;

class PayrollRepository
{
    protected $model;

    public function __construct(Payroll $payroll)
    {
        $this->model = $payroll;
    }

    /**
     * Get all payrolls with filters
     */
    public function getAll(array $filters = [])
    {
        $query = $this->model->with('employee');

        if (isset($filters['employee_id'])) {
            $query->where('employee_id', $filters['employee_id']);
        }

        if (isset($filters['month']) && isset($filters['year'])) {
            $query->where('period_month', $filters['month'])
                ->where('period_year', $filters['year']);
        }

        return $query->orderBy('period_year', 'desc')
            ->orderBy('period_month', 'desc')
            ->paginate(20);
    }

    /**
     * Find payroll by ID
     */
    public function findById(int $id)
    {
        return $this->model->with('employee')->findOrFail($id);
    }

    /**
     * Create payroll
     */
    public function create(array $data)
    {
        return $this->model->create($data);
    }

    /**
     * Update payroll
     */
    public function update(int $id, array $data)
    {
        $payroll = $this->findById($id);
        $payroll->update($data);
        return $payroll;
    }

    /**
     * Delete payroll
     */
    public function delete(int $id): bool
    {
        $payroll = $this->findById($id);
        return $payroll->delete();
    }



    /**
     * Get payrolls for specific period
     */
    public function getByPeriod(int $month, int $year)
    {
        return $this->model->with('employee')
            ->where('period_month', $month)
            ->where('period_year', $year)
            ->get();
    }


}
