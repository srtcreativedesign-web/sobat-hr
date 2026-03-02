<?php

namespace App\Traits;

trait ExcelSanitizer
{
    /**
     * Sanitize values for Excel to prevent CSV/Formula injection.
     * Prefixes strings starting with dangerous characters with a single quote.
     */
    protected function sanitizeExcelValue($value)
    {
        if (is_string($value) && !empty($value)) {
            $dangerousCharacters = ['=', '+', '-', '@'];
            
            if (in_array(substr($value, 0, 1), $dangerousCharacters)) {
                return "'" . $value;
            }
        }
        
        return $value;
    }

    /**
     * Sanitize an entire array of values.
     */
    protected function sanitizeArray(array $data)
    {
        return array_map([$this, 'sanitizeExcelValue'], $data);
    }
}
