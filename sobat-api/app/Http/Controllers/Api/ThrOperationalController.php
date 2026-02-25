<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\ThrController;
use Illuminate\Http\Request;

class ThrOperationalController extends ThrController
{
    /**
     * Display a listing of Operational thrs
     */
    public function index(Request $request)
    {
        return parent::index($request);
    }

    /**
     * Import Operational THR
     */
    public function import(Request $request)
    {
        // Custom Operational internal mapping if needed
        return parent::import($request);
    }
}
