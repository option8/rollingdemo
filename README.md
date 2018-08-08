# Rolling
A mixed display mode demo for the Apple IIe, written in 6502 Assembly

Uses $C019 on the IIe to detect the VBL interval and some cycle counting to switch display modes during the screen draw for a mix of low-res and text modes.

# Scroll
I had some fun working out how quickly to scroll low res text and keep it legible. Each row of text scrolls 1 pixel left when the one above it has scrolled all the way across the screen. The top scrolls as fast as I could manage, and the bottom one, well, it will eventually.

