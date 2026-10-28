// Watches for a click outside the open panel: run by popup_watch.sh with the panel's rectangle.
// Reading which mouse buttons are down needs no permission, unlike listening for clicks.
// Prints "outside" at the first press that lands outside both the panel and the bar, "timeout" otherwise.
ObjC.import("AppKit");

function run(argv) {
  const [x0, y0, x1, y1, barHeight, timeout] = argv.map(Number);
  const screenHeight = $.NSScreen.screens.objectAtIndex(0).frame.size.height;
  const deadline = Date.now() + timeout * 1000;
  let wasDown = $.NSEvent.pressedMouseButtons != 0;
  while (Date.now() < deadline) {
    $.NSThread.sleepForTimeInterval(0.04);
    const down = $.NSEvent.pressedMouseButtons != 0;
    if (down && !wasDown) {
      const point = $.NSEvent.mouseLocation;
      const x = point.x;
      const y = screenHeight - point.y; // from the top, like sketchybar's rectangles
      const inBar = y < barHeight;
      const inPanel = x >= x0 && x <= x1 && y >= y0 && y <= y1;
      if (!inBar && !inPanel) {
        return "outside";
      }
    }
    wasDown = down;
  }
  return "timeout";
}
