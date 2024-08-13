window.onload = function () {
    const videoPlayer = document.getElementById("video-player");
    if (videoPlayer) {
        videoPlayer.scrollIntoView({behavior: "smooth", block: "center"});
    }
};