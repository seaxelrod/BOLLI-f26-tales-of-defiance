/**
 * nav-sync.js - Complete Shared Navigation & Synchronization
 */

(function () {
  const fallbackPage = './under-construction.html';

  // -------------------------------------------------------------
  // 1. RUNNING IN PARENT WINDOW (index.html)
  // -------------------------------------------------------------
  if (window.self === window.top) {
    document.addEventListener('DOMContentLoaded', function () {
      const select = document.getElementById('page-select');
      const iframe = document.getElementById('main-content');

      if (!select || !iframe) return;

      // Master navigation function
	window.navigateToCoursePage = function (targetUrl) {
	    if (!targetUrl) return;
	    
	    const baseFilename = targetUrl.split('#')[0];
	    
	    // 1. Immediately update dropdown UI & storage
	    if (baseFilename && select) {
		select.value = baseFilename;
		localStorage.setItem('selectedCoursePage', baseFilename);
	    }
	    
	    // 2. Test file existence
	    fetch(baseFilename, { method: 'GET', cache: 'no-store' })
		.then(response => {
		    if (response.ok) {
			iframe.src = targetUrl;
		    } else {
			console.log(`Setting iframe src to fallback: ${fallbackPage}`);
			iframe.src = fallbackPage;
		    }
		})
		.catch(() => {
		    console.log(`Fetch rejected. Setting iframe src to fallback: ${fallbackPage}`);
		    iframe.src = fallbackPage;
		});
	};
	
	// Initial restore on page load
	const savedPage = localStorage.getItem('selectedCoursePage') || 'home.html';
	window.navigateToCoursePage(savedPage);
	
	// Handle user choosing from the dropdown menu
	select.addEventListener('change', function (e) {
            window.navigateToCoursePage(e.target.value);
	});
    });
  } 
    
    // -------------------------------------------------------------
    // 2. RUNNING INSIDE THE IFRAME (Sub-pages: home.html, week1.html, etc.)
    // -------------------------------------------------------------
    else {
	document.addEventListener('DOMContentLoaded', function () {
	    document.querySelectorAll('a').forEach(link => {
		// External links -> open in new tab
		if (link.hostname && link.hostname !== window.location.hostname) {
		    link.setAttribute('target', '_blank');
		    link.setAttribute('rel', 'noopener');
		} 
		// Internal relative links -> delegate navigation to parent
		else {
		    const href = link.getAttribute('href');
		    if (!href || href.startsWith('#') || href.startsWith('javascript:')) return;
		    
		    link.addEventListener('click', function (e) {
			e.preventDefault();
			if (window.parent && typeof window.parent.navigateToCoursePage === 'function') {
			    window.parent.navigateToCoursePage(href);
			} else {
			    window.location.href = href;
			}
		    });
		}
	    });
	});
    }
})();
