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
      // Ensure external links open in a new tab without breaking the parent frame
      document.querySelectorAll('a').forEach(link => {
        if (link.hostname && link.hostname !== window.location.hostname) {
          link.setAttribute('target', '_blank');
          link.setAttribute('rel', 'noopener');
        }
      });
    });
  }
})();
