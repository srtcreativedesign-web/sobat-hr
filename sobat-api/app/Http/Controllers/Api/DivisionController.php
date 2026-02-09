<?php

namespace App\Http\Controllers\Api;


use App\Http\Controllers\Controller;
use App\Models\Organization;
use Illuminate\Http\Request;

class DivisionController extends Controller
{
    /**
     * Display a listing of the resource.
     * Returns organizations as divisions for dropdown purposes
     */
    public function index()
    {
        return response()->json(
            Organization::select('id', 'name', 'code', 'type')
                ->orderBy('name')
                ->get()
        );
    }
}

