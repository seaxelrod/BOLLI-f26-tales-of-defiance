/**
 * nav-sync.js - Shared Navigation & Iframe Synchronization
 */

(function () {
  // Check if we are running in the PARENT window (index.html)
  if (window.self === window.top) {
    document.addEventListener('DOMContentLoaded', function () {
      const select = document.getElementById('page-select');
      const iframe = document.getElementById('main-content');
      const fallbackPage = 'under-construction.html';

      if (!select || !iframe) return;

      // Helper to update the iframe src safely
      function loadPage(url) {
        if (!url) return;
        iframe.src = url;
        const baseFilename = url.split('#')[0];
        if (baseFilename) {
          localStorage.setItem('selectedCoursePage', baseFilename);
        }
      }

      // Expose a helper for direct script navigation
      window.navigateToCoursePage = function (targetUrl) {
        const baseFilename = targetUrl.split('#')[0];
        if (select && baseFilename) select.value = baseFilename;
        loadPage(targetUrl);
      };

      // 1. Initial page load from localStorage
      const savedPage = localStorage.getItem('selectedCoursePage') || 'home.html';
      select.value = savedPage;
      loadPage(savedPage);

      // 2. Sync when user selects an option in the dropdown
      select.addEventListener('change', function (e) {
        loadPage(e.target.value);
      });

      // 3. Sync dropdown automatically when a link is clicked INSIDE the iframe
      iframe.addEventListener('load', function () {
        try {
          const framePath = iframe.contentWindow.location.pathname;
          const currentFile = framePath.substring(framePath.lastIndexOf('/') + 1);

          if (currentFile && select.value !== currentFile) {
            // Check if currentFile is an option in our select element
            const optionExists = Array.from(select.options).some(
              opt => opt.value === currentFile
            );
            if (optionExists) {
              select.value = currentFile;
              localStorage.setItem('selectedCoursePage', currentFile);
            }
          }
        } catch (e) {
          // Handled gracefully if security/CORS prevents reading local frame
        }
      });
    });
  } 
  
 // Check if we are running INSIDE the iframe (sub-pages)
  else {
    document.addEventListener('DOMContentLoaded', function () {
      const fallbackPage = 'under-construction.html';

      document.querySelectorAll('a').forEach(link => {
        // 1. External Links: open in a new tab
        if (link.hostname && link.hostname !== window.location.hostname) {
          link.setAttribute('target', '_blank');
          link.setAttribute('rel', 'noopener');
        } 
        // 2. Internal / Relative Links: intercept and validate
        else {
          const href = link.getAttribute('href');
          
          // Skip pure anchor jumps on the same page (#section) or empty links
          if (!href || href.startsWith('#') || href.startsWith('javascript:')) {
            return;
          }

          link.addEventListener('click', function(e) {
            e.preventDefault();

            // Extract the base target URL (without hash)
            const targetUrl = href.split('#')[0];

            // Verify if the local file exists before navigating
            fetch(targetUrl, { method: 'GET', cache: 'no-store' })
              .then(response => {
                if (response.ok) {
                  // File exists -> navigate normally
                  window.location.href = href;
                } else {
                  // 404 -> route to under-construction page
                  window.location.href = fallbackPage;
                }
              })
              .catch(() => {
                // Fetch failed / file not found
                window.location.href = fallbackPage;
              });
          });
        }
      });
    });
  } // Check if we are running INSIDE the iframe (sub-pages)
})();
