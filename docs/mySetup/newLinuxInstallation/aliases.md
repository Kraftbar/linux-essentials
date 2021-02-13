youtube-dl-480='youtube-dl -f "bestvideo[height<=480][ext=mp4]+bestaudio[ext=m4a]" '
youtube-dl-720='youtube-dl -f "bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]" '
youtube-dl-best='youtube-dl -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio" '
youtube-dl-mp3='youtube-dl --extract-audio -f bestaudio[ext=mp3] --no-playlist '
myredshift='pgrep redshift | xargs -n1 kill -9 && redshift -l 59.904379299999995:10.7004307 2500'


todo: Make this an alias     
youtube-dl-best --output "%(upload_date)s%(title)s.%(ext)s"
