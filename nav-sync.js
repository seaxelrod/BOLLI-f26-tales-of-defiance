/**
 * nav-sync.js - Complete Shared Navigation & Synchronization
 */

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
          // Get the actual file name currently inside the iframe
          const currentPath = iframe.contentWindow.location.pathname;
          const currentFilename = currentPath.substring(currentPath.lastIndexOf('/') + 1);

          if (currentFilename && currentFilename !== fallbackPage) {
            select.value = currentFilename;
            localStorage.setItem('selectedCoursePage', currentFilename);
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

        const baseFilename = targetUrl.split('#')[0];

        // Test file existence
        fetch(baseFilename, { method: 'HEAD', cache: 'no-store' })
          .then(response => {
            if (response.ok) {
              iframe.src = targetUrl;
            } else {
              console.log(`Target not found. Setting fallback: ${fallbackPage}`);
              iframe.src = fallbackPage;
            }
          })
          .catch(() => {
            console.log(`Fetch failed. Setting fallback: ${fallbackPage}`);
            iframe.src = fallbackPage;
          });
      };


      // Check if a specific subpage was passed in the URL (e.g. index.html?page=DMC_week2.html)
      const urlParams = new URLSearchParams(window.location.search);
      const pageFromUrl = urlParams.get('page');

      // Priority: 1. URL Parameter -> 2. LocalStorage -> 3. Default Syllabus
      const savedPage = pageFromUrl || localStorage.getItem('selectedCoursePage') || 'DMC_syllabus.html';

      select.value = savedPage;
      window.navigateToCoursePage(savedPage);

      // Handle user manually changing the dropdown menu
      select.addEventListener('change', function (e) {
        window.navigateToCoursePage(e.target.value);
      });
    });
  }

  // -------------------------------------------------------------
  // 2. RUNNING INSIDE THE IFRAME (Sub-pages: DMC_syllabus.html, etc.)
  // -------------------------------------------------------------

  else {
      document.addEventListener('DOMContentLoaded', function() {
	  // Replace with your actual live site root URL:
	  const liveSiteBase = 'https://seaxelrod.github.io/BOLLI-f26-tales-of-defiance/'
	  
	  document.querySelectorAll('a').forEach(link => {
	      const rawHref = link.getAttribute('href');
	      
	      /*
                ** Uncomment (and remove standalone next line)  to point to live site even if viewing as file or on local website.
                ** Since we don't wan't file and html to point to live site, we leave this comment.
                **
	        // If viewing locally from disk, rewrite to the live website
  	        if (window.location.protocol === 'file:' && rawHref && !rawHref.startsWith('http') && !rawHref.startsWith('mailto:')) {
		    link.setAttribute('href', new URL(rawHref, liveSiteBase).href);
	        } 
	        // Otherwise, use the active domain URL
	        else if (link.href) {
		    link.setAttribute('href', link.href);
	        }

               */
	      if(link.href) {link.setAttribute('href', link.href);}
	      
	      // Open external links in a new tab
	      if (link.hostname && link.hostname !== window.location.hostname) {
		  link.setAttribute('target', '_blank');
		  link.setAttribute('rel', 'noopener');
	      }
	  });
      });
  }
})();


