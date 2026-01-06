<?php

namespace App\Repositories;

use App\Models\Employee;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Pagination\LengthAwarePaginator;

class EmployeeRepository
{
    protected $model;

    public function __construct(Employee $employee)
    {
        $this->model = $employee;
    }

    /**
     * Get all employees with optional filters
     */
    public function getAll(array $filters = [], int $perPage = 20): LengthAwarePaginator
    {
        $query = $this->model->with(['user', 'organization', 'role']);

        if (isset($filters['organization_id'])) {
            $query->where('organization_id', $filters['organization_id']);
        }

        if (isset($filters['status'])) {
            $query->where('status', $filters['status']);
        }

        if (isset($filters['search'])) {
            $search = $filters['search'];
            $query->where(function($q) use ($search) {
                $q->where('full_name', 'like', "%{$search}%")
                  ->orWhere('employee_number', 'like', "%{$search}%");
            });
        }

        return $query->paginate($perPage);
    }

    /**
     * Find employee by ID
     */
    public function findById(int $id)
    {
        return $this->model->with(['user', 'organization', 'role', 'attendances', 'payrolls'])
            ->findOrFail($id);
    }

    /**
     * Create new employee
     */
    public function create(array $data)
    {
        return $this->model->create($data);
    }

    /**
     * Update employee
     */
    public function update(int $id, array $data)
    {
        $employee = $this->findById($id);
        $employee->update($data);
        return $employee;
    }

    /**
     * Delete employee
     */
    public function delete(int $id): bool
    {
        $employee = $this->findById($id);
        return $employee->delete();
    }

    /**
     * Get employee attendances
     */
    public function getAttendances(int $id, array $filters = [])
    {
        $employee = $this->findById($id);
        $query = $employee->attendances();

        if (isset($filters['month']) && isset($filters['year'])) {
            $query->whereMonth('date', $filters['month'])
                  ->whereYear('date', $filters['year']);
        }

        return $query->orderBy('date', 'desc')->paginate(31);
    }

    /**
     * Get employee payrolls
     */
    public function getPayrolls(int $id)
    {
        $employee = $this->findById($id);
        return $employee->payrolls()
            ->orderBy('period_month', 'desc')
            ->orderBy('period_year', 'desc')
            ->paginate(12);
    }
}
