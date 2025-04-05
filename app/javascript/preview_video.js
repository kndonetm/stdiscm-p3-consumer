document.addEventListener("DOMContentLoaded", function() {
    const videos = document.querySelectorAll(".preview-video");
  
    videos.forEach(video => {
      let timeout;
      let isHovering = false;
  
      function startLoop() {
        if (!isHovering) return;
  
        video.currentTime = 0;
        video.play().catch(function(error) {
          console.error("Error playing video:", error);
        });
  
        timeout = setTimeout(() => {
          video.pause();
          video.currentTime = 0;
          setTimeout(() => {
            startLoop(); 
          }, 5); // 5ms pause before looping
        }, 10000); // 10 seconds preview
      }
  
      video.addEventListener("mouseenter", () => {
        isHovering = true;
        startLoop();
      });
  
      video.addEventListener("mouseleave", () => {
        isHovering = false;
        clearTimeout(timeout);
        video.pause();
        video.currentTime = 0;
      });
    });
  });
  