<?php

return [
    'locations' => [
        [
            'id' => 'office',
            'name' => 'Office',
            'latitude' => (float) env('ATTENDANCE_OFFICE_LAT', -6.13778),
            'longitude' => (float) env('ATTENDANCE_OFFICE_LNG', 106.62295),
            'radius_meters' => (int) env('ATTENDANCE_OFFICE_RADIUS', 100),
        ],
        [
            'id' => 'gudang_b3',
            'name' => 'Gudang B3',
            'latitude' => (float) env('ATTENDANCE_GUDANG_B3_LAT', -6.134087),
            'longitude' => (float) env('ATTENDANCE_GUDANG_B3_LNG', 106.623301),
            'radius_meters' => (int) env('ATTENDANCE_GUDANG_B3_RADIUS', 100),
        ],
        [
            'id' => 'training_centre',
            'name' => 'Training Centre',
            'latitude' => (float) env('ATTENDANCE_TC_LAT', -6.133417),
            'longitude' => (float) env('ATTENDANCE_TC_LNG', 106.629707),
            'radius_meters' => (int) env('ATTENDANCE_TC_RADIUS', 100),
        ],
    ],
    'tolerance_meters' => (int) env('ATTENDANCE_GEOFENCE_TOLERANCE', 10),
];
