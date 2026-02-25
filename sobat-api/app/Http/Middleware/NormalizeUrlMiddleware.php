<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class NormalizeUrlMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $uri = $request->getRequestUri();
        
        // Check if there are multiple consecutive slashes
        if (preg_match('/\/{2,}/', $uri)) {
            // Collapse multiple slashes into one, but keep the initial one
            $normalizedUri = preg_replace('/\/{2,}/', '/', $uri);
            
            // Reinitialize the request with the new URI or redirect?
            // Use 308 Permanent Redirect to preserve POST method and data
            return redirect($normalizedUri, 308);
        }

        return $next($request);
    }
}
