/**
 * nav-sync.js - Complete Shared Navigation & Synchronization
 */

// 1. Set your current course version (Update this number when you push mid-course changes)
const COURSE_VERSION = "v3"; 

// 2. Check if the student's browser has an older version saved
if (localStorage.getItem("course_version") !== COURSE_VERSION) {
    // 3. If it is old (or their first visit), wipe all saved local storage for this site
    localStorage.clear(); 
    
    // 4. Save the new version number so it doesn't wipe again until you change it to "v3"
    localStorage.setItem("course_version", COURSE_VERSION);
}



(function () {
  const fallbackPage = 'under-construction.html';

  // -------------------------------------------------------------
  // 1. RUNNING IN PARENT WINDOW (index.html)
  // -------------------------------------------------------------
  if (window.self === window.top) {
    document.addEventListener('DOMContentLoaded', function () {
      const select = document.getElementById('page-select');
      const iframe = document.getElementById('main-content');

      if (!select || !iframe) return;

      // Function to synchronize the dropdown with what the iframe is actually displaying
      function syncDropdownToIframe() {
        try {
          const iframePath = iframe.contentWindow.location.pathname;
          
          // 1. Get the directory containing index.html (e.g. "/course-site/" or "/")
          const parentDir = window.location.pathname.substring(0, window.location.pathname.lastIndexOf('/') + 1);
          
          // 2. Strip the parent directory path, preserving subdirectories
          let relativePath = iframePath;
          if (relativePath.startsWith(parentDir)) {
            relativePath = relativePath.slice(parentDir.length);
          }
          
          if (relativePath && relativePath !== fallbackPage) {
            // 3. Find the option whose resolved path matches the iframe's path
            const match = Array.from(select.options).find(opt => {
              if (!opt.value) return false;
              return new URL(opt.value, window.location.href).pathname === iframePath;
            });
            
            if (match) {
              select.value = match.value;
              localStorage.setItem('selectedCoursePage', match.value);
            }
          }
        } catch (e) {
          // Security safeguard if loading across different origins
          console.warn('Could not read iframe location:', e);
        }
      }

      // Listen for when the iframe finishes loading ANY page (including Back/Forward navigation)
      iframe.addEventListener('load', syncDropdownToIframe);

      // Master navigation function for programmatic changes
      window.navigateToCoursePage = function (targetUrl) {
        if (!targetUrl) return;

        // Immediately update dropdown & storage
        select.value = targetUrl;
        localStorage.setItem('selectedCoursePage', targetUrl);

        // Navigate iframe directly
        try {
          if (iframe.contentWindow && iframe.contentWindow.location) {
            iframe.contentWindow.location.href = targetUrl;
          } else {
            iframe.src = targetUrl;
          }
        } catch (e) {
          iframe.src = targetUrl;
        }
      };

      // Check if a specific subpage was passed in the URL (e.g. index.html?page=DMC_week2.html)
      const urlParams = new URLSearchParams(window.location.search);
      const pageFromUrl = urlParams.get('page') || urlParams.get('page-select');

      // Priority: 1. URL Parameter -> 2. LocalStorage -> 3. Default Welcome 
      const savedPage = pageFromUrl || localStorage.getItem('selectedCoursePage') || 'DMC_welcome.html';

      select.value = savedPage;
      window.navigateToCoursePage(savedPage);

      // Handle user manually changing the dropdown menu
      select.addEventListener('change', function (e) {
        window.navigateToCoursePage(e.target.value);
      });
    });
  }

  // -------------------------------------------------------------
  // 2. RUNNING INSIDE THE IFRAME (Sub-pages: DMC_welcome.html, etc.)
  // -------------------------------------------------------------
  else {
    document.addEventListener('DOMContentLoaded', function () {
      // 1. Frame-busting guard: if index.html is loaded inside the iframe, break out immediately
      if (document.getElementById('main-content')) {
        window.top.location.href = window.location.href;
        return;
      }

      // 2. Dynamically determine the base directory where index.html lives on THIS server
      let baseDir = '/';
      try {
        const parentPath = window.top.location.pathname;
        baseDir = parentPath.substring(0, parentPath.lastIndexOf('/') + 1);
      } catch (e) {
        baseDir = window.location.pathname.substring(0, window.location.pathname.lastIndexOf('/') + 1);
      }

      const cleanBaseDir = baseDir.replace(/\/$/, '');
      const indexPath = baseDir + 'index.html';

      document.querySelectorAll('a').forEach(link => {
        if (!link.href) return;

        // A. External links -> open in new tab
        if (link.hostname && link.hostname !== window.location.hostname) {
          link.setAttribute('target', '_blank');
          link.setAttribute('rel', 'noopener');
          return;
        }

        const url = new URL(link.href, window.location.href);

        // B. In-page anchor jump on the exact same page -> keep inside frame
        if (url.pathname === window.location.pathname && url.search === window.location.search) {
          return;
        }

        // C. Base site links -> navigate parent to welcome
        const linkPath = url.pathname.replace(/\/$/, '');
        const isBaseSite = (url.pathname === baseDir) ||
                           (cleanBaseDir !== '' && linkPath === cleanBaseDir) ||
                           (url.pathname === indexPath);

        if (isBaseSite) {
          link.addEventListener('click', function (e) {
            e.preventDefault();
            const target = url.searchParams.get('page') ||
                           url.searchParams.get('page-select') ||
                           'DMC_welcome.html';

            if (window.parent && typeof window.parent.navigateToCoursePage === 'function') {
              window.parent.navigateToCoursePage(target);
            } else {
              window.location.href = target;
            }
          });
          return;
        }

        // D. Internal course pages: check if the target exists in the parent dropdown
        let isInDropdown = false;
        try {
          const parentSelect = window.parent.document.getElementById('page-select');
          if (parentSelect) {
            const parentBaseUrl = window.parent.location.href;
            isInDropdown = Array.from(parentSelect.options).some(opt => {
              if (!opt.value) return false;
              return new URL(opt.value, parentBaseUrl).pathname === url.pathname;
            });
          }
        } catch (e) {
          console.warn('Could not inspect parent dropdown:', e);
        }

        // If not in the dropdown, force it to open in a new, unframed browser tab
        if (!isInDropdown) {
          link.setAttribute('target', '_blank');
          link.setAttribute('rel', 'noopener');
        }
      });
    });
  }
})();
