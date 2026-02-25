<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\ThrController;
use Illuminate\Http\Request;

class ThrHoController extends ThrController
{
    /**
     * Display a listing of HO thrs
     */
    public function index(Request $request)
    {
        // For HO, we might want to filter by division if needed, 
        // but for now let's use the parent index with year filter
        return parent::index($request);
    }

    /**
     * Import HO THR
     */
    public function import(Request $request)
    {
        // Custom HO internal mapping if needed
        // For now, parent import is robust enough as it uses header detection
        return parent::import($request);
    }
}
