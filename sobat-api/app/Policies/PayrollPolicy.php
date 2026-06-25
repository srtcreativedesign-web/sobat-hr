<?php

namespace App\Policies;

use App\Models\Payroll;
use App\Models\User;
use App\Models\Role;
use Illuminate\Auth\Access\Response;

class PayrollPolicy
{
    /**
     * Determine whether the user can perform admin actions (view all, update, approve).
     */
    private function isAdmin(User $user): bool
    {
        $roleName = $user->role ? strtolower($user->role->name) : '';
        return in_array($roleName, [Role::ADMIN, Role::SUPER_ADMIN, Role::HR, Role::HRD, Role::ADMIN_CABANG, 'admin_hr']);
    }

    /**
     * Check if user is an HR admin specifically for operational/store employees.
     */
    private function isHrAdminForOperational(User $user, Payroll $payroll): bool
    {
        $roleName = $user->role ? strtolower($user->role->name) : '';
        if ($roleName === 'admin_hr') {
            // admin_hr cannot access Head Office payrolls
            if ($payroll->employee && strtolower($payroll->employee->track) === 'office') {
                return false;
            }
            return true;
        }
        return false;
    }

    /**
     * Determine whether the user can view the model.
     */
    public function view(User $user, Payroll $payroll): Response
    {
        if ($this->isAdmin($user)) {
            $roleName = $user->role ? strtolower($user->role->name) : '';
            if ($roleName === 'admin_hr' && $payroll->employee && strtolower($payroll->employee->track) === 'office') {
                return Response::deny('Anda tidak memiliki akses ke data payroll Head Office.');
            }
            return Response::allow();
        }

        // Standard user can only view their own
        if ($payroll->employee_id === $user->employee?->id) {
            return Response::allow();
        }

        return Response::deny('Anda tidak memiliki akses ke data payroll ini.');
    }

    /**
     * Determine whether the user can update the model.
     */
    public function update(User $user, Payroll $payroll): Response
    {
        return $this->view($user, $payroll);
    }

    /**
     * Determine whether the user can delete the model.
     */
    public function delete(User $user, Payroll $payroll): Response
    {
        return $this->view($user, $payroll);
    }
    
    /**
     * Determine whether the user can approve the model.
     */
    public function approve(User $user, Payroll $payroll): Response
    {
        if (!$this->isAdmin($user)) {
            return Response::deny('Anda tidak memiliki hak untuk menyetujui payroll.');
        }

        $roleName = $user->role ? strtolower($user->role->name) : '';
        if ($roleName === 'admin_hr' && $payroll->employee && strtolower($payroll->employee->track) === 'office') {
            return Response::deny('Anda tidak memiliki akses untuk menyetujui data payroll Head Office.');
        }

        return Response::allow();
    }
    
    /**
     * Determine whether the user can approve any model (bulk).
     */
    public function approveAny(User $user): Response
    {
        if (!$this->isAdmin($user)) {
            return Response::deny('Anda tidak memiliki hak untuk menyetujui payroll.');
        }

        return Response::allow();
    }
}
