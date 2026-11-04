/**
 * nav-sync.js - Complete Shared Navigation & Synchronization
 */

const COURSE_VERSION = "v3"; 

if (localStorage.getItem("course_version") !== COURSE_VERSION) {
    localStorage.clear(); 
    localStorage.setItem("course_version", COURSE_VERSION);
}

(function () {
  // -------------------------------------------------------------
  // 1. RUNNING IN PARENT WINDOW (index.html)
  // -------------------------------------------------------------
  if (window.self === window.top) {
    document.addEventListener('DOMContentLoaded', function () {
      const select = document.getElementById('page-select');
      const iframe = document.getElementById('main-content');

      if (!select || !iframe) return;

      const parentBaseUrl = window.location.href;

      // Sync dropdown when iframe finishes loading
      function syncDropdownToIframe() {
        try {
          const iframePath = iframe.contentWindow.location.pathname;

          const match = Array.from(select.options).find(opt => {
            if (!opt.value) return false;
            return new URL(opt.value, parentBaseUrl).pathname === iframePath;
          });

          if (match) {
            select.value = match.value;
            localStorage.setItem('selectedCoursePage', match.value);
          }
        } catch (e) {
          console.warn('Could not read iframe location:', e);
        }
      }

      iframe.addEventListener('load', syncDropdownToIframe);

      // Programmatic navigation
      window.navigateToCoursePage = function (targetValue) {
        if (!targetValue) return;

        const targetUrl = new URL(targetValue, parentBaseUrl).href;

        select.value = targetValue;
        localStorage.setItem('selectedCoursePage', targetValue);

        try {
          if (iframe.contentWindow && iframe.contentWindow.location) {
            if (iframe.contentWindow.location.href !== targetUrl) {
              iframe.contentWindow.location.href = targetUrl;
            }
          } else {
            iframe.src = targetValue;
          }
        } catch (e) {
          iframe.src = targetValue;
        }
      };

      // Determine initial page
      const urlParams = new URLSearchParams(window.location.search);
      const initialPage = urlParams.get('page') || 
                          urlParams.get('page-select') || 
                          localStorage.getItem('selectedCoursePage') || 
                          'DMC_welcome.html';

      select.value = initialPage;
      const initialTargetUrl = new URL(initialPage, parentBaseUrl).href;
      if (iframe.src !== initialTargetUrl) {
        iframe.src = initialPage;
      }

      select.addEventListener('change', function (e) {
        window.navigateToCoursePage(e.target.value);
      });
    });
  }

  // -------------------------------------------------------------
  // 2. RUNNING INSIDE THE IFRAME (Sub-pages)
  // -------------------------------------------------------------
  else {
    document.addEventListener('DOMContentLoaded', function () {
      // Prevent index.html from ever nesting inside itself
      if (document.getElementById('main-content')) {
        window.top.location.href = window.location.href;
        return;
      }

      let parentSelect = null;
      let parentBaseUrl = '';

      try {
        if (window.parent && window.parent.document) {
          parentSelect = window.parent.document.getElementById('page-select');
          parentBaseUrl = window.parent.location.href;
        }
      } catch (e) {
        console.warn('Cannot access parent frame:', e);
      }

      document.querySelectorAll('a').forEach(link => {
        if (!link.href) return;

        // External links -> open in new tab
        if (link.hostname && link.hostname !== window.location.hostname) {
          link.setAttribute('target', '_blank');
          link.setAttribute('rel', 'noopener');
          return;
        }

        const url = new URL(link.href, window.location.href);

        // Same-page anchor jump (#section) -> allow default behavior
        if (url.pathname === window.location.pathname && url.search === window.location.search) {
          return;
        }

        // Check if the destination exists in the top dropdown
        if (parentSelect && parentBaseUrl) {
          const matchingOption = Array.from(parentSelect.options).find(opt => {
            if (!opt.value) return false;
            return new URL(opt.value, parentBaseUrl).pathname === url.pathname;
          });

          if (matchingOption) {
            // Target is an official course unit: route through parent nav
            link.addEventListener('click', function (e) {
              e.preventDefault();
              if (typeof window.parent.navigateToCoursePage === 'function') {
                window.parent.navigateToCoursePage(matchingOption.value);
              } else {
                window.location.href = url.href;
              }
            });
            return;
          }
        }

        // Links not in dropdown: open normally in a new tab without frame interception
        link.setAttribute('target', '_blank');
        link.setAttribute('rel', 'noopener');
      });
    });
  }
})();
