from django.utils.deprecation import MiddlewareMixin

class SecurityHeadersMiddleware(MiddlewareMixin):
    def process_response(self, request, response):
        # Allow Phantom wallet connection
        response["Cross-Origin-Opener-Policy"] = "same-origin-allow-popups"
        
        # Content Security Policy
        csp_policies = [
            "default-src 'self'",
            "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.tailwindcss.com https://unpkg.com https://bundle.run",
            "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
            "font-src 'self' https://fonts.gstatic.com",
            "img-src 'self' data: blob: https:",
            "connect-src 'self' https://api.devnet.solana.com https://api.mainnet-beta.solana.com",
            "frame-src 'self' https://phantom.app"
        ]
        
        response["Content-Security-Policy"] = "; ".join(csp_policies)
        return response