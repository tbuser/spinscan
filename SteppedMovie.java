import processing.core.*;
import processing.video.*;

/**
 * SteppedMovie
 * Dave Bollinger (davebollinger.com)
 * A subclass of processing.video.Movie that operates in
 * "step" mode, allowing individual frame seek and access.
 * This class is <b>not</b> intended for real-time playback.
 *
 * Motivation:  There's no reliable way with the existing Movie
 * class's methods to <b>guarantee</b> you've processed every
 * single frame in a movie.  Why?  Movie's movieEvent() isn't
 * actually based on the movie data at all.  Rather it's based
 * on a timer thread that *approximates* the movie's playback
 * rate.  It's easy to desync this event from movie frames, or
 * from the draw() loop's own timer thread, and whenever that
 * happens you'll lose, or 'leak', some frames.  Further, read()
 * uses the movie's <b>real</b> time position to extract the
 * frame, so you're not even guaranteed to get the same 'frame'
 * that movieEvent() notified you about if there's any delay
 * at all between that event and your call to read() (fe, event
 * is async, read() commonly synced with next draw() loop - those
 * are almost guaranteed to be out of sync w/ each other).  Further,
 * pause() and stop() don't do what you might expect -- all they
 * do is prevent the timer thread from generating events, while
 * movie time continues to advance, so the next read() skips all
 * frames that occurred during pause()/stop().
 *
 * All of that behaviour is just fine if you want real-time
 * playback, and don't care if you have to drop frames to do so.
 * But it's not helpful at all if you want to process every frame
 * where realtime isn't a concern.  Thus this subclass.
 *
 * Caveat:  These observations were made of (and this class motivated
 * by) QuickTime's performance under Windows.  QuickTime under other
 * O/S's may behave differently, I can neither confirm nor deny.
 *
 * Aside:  Processing 1.2's existing Video library (based on QuickTime)
 * is soon to be replaced/deprecated, but of the other 3rd party
 * video library options (GSVideo, JMCVideo, OpenCV, etc), OpenCV is
 * the only one that currently appears to support seeking to specific
 * numbered frames (others may support seeking by time, though that's
 * less precise).  So QT still appears the best approach.  (at least,
 * for my needs - your mileage may vary)
 *
 * Example usage:
 * <code>
 * import processing.video.*;
 * SteppedMovie movie = new SteppedMovie(this,"original.mov");
 * movie.read(); // need a read() before can retrieve width/height
 * MovieMaker maker = new MovieMaker(this,movie.width,movie.height,"modified.mov",30, MovieMaker.H263, MovieMaker.HIGH);
 * while (!movie.done()) {
 *   movie.read();
 *   movie.filter(POSTERIZE,3);
 *   movie.filter(BLUR,3);
 *   maker.addFrame(movie.pixels,movie.width,movie.height);
 *   movie.stepForward();
 * }
 * maker.finish();
 * </code>
 */
public class SteppedMovie extends Movie {
  /** The current frame number */
  protected int currentFrameNumber;
  /** The current frame time (using internal time units) */
  protected int currentFrameTime;
  /** An indication if step overstepped the time bounds */
  protected boolean done;
  /** If precalc() is called, this will contain the total frame count */
  protected int precalcedFrameCount;
  /** If precalc() is called, this will contain the times for each frame */
  protected int [] precalcedFrameTimes;
  /** Constructor */
  public SteppedMovie(PApplet parent, String filename) { super(parent,filename); reset(); }
  /** Constructor */
  public SteppedMovie(final PApplet parent, final String filename, final int ifps) { super(parent,filename,ifps); reset(); }
  /** This method no longer has a useful meaning in this subclass, it is non-functional */
  @Override public void play() {}
  /** This method no longer has a useful meaning in this subclass, it is non-functional */
  @Override public void loop() {}
  /** This method no longer has a useful meaning in this subclass, it is non-functional */
  @Override public void noLoop() {}
  /** This method no longer has a useful meaning in this subclass, it is non-functional */
  @Override public void pause() {}
  /** This method no longer has a useful meaning in this subclass, it is non-functional */
  @Override public void stop() {}
  /**
   * Scans through the movie and stores the time of each
   * individual frame.  This can be tremendously useful <b>if</b>
   * the movie is relatively short (has few frames) and
   * you'll be doing lots of random frame seeking.  The
   * internal step*() and goto*() routines will use these
   * precalced times, if available, to improve performance.
   */
  public int precalcFrameTimes() {
    // pass 1 - step thru and count frames
    gotoFirstFrame();
    while (!done) {
      step(1);
    }
    precalcedFrameCount = currentFrameNumber + 1;
    // pass 2 - step thru and store frame times
    int [] tempPrecalcedFrameTimes = new int[precalcedFrameCount];
    gotoFirstFrame();
    while (!done) {
      tempPrecalcedFrameTimes[currentFrameNumber] = currentFrameTime;
      step(1);
    }
    precalcedFrameTimes = tempPrecalcedFrameTimes;
    // reset movie to first frame and return frame count
    gotoFirstFrame();
    return precalcedFrameCount;
  }
  /**
   * done() == true whenever you try to step 'beyond' the movie duration - 
   * either step(-1) when at frame zero,
   * or step(1) when at the last frame.
   * It does <b>not</b> mean the movie can't be seeked any more, just that
   * the last seek performed would have ended a typical "play" operation.
   * It is intended to be used as an 'end condition' when processing all
   * frames in sequential order.
   * Any subsequent successful goto*() or step*() (in the opposite direction
   * of that failed step, obviously) will reset it to false.
   */
  public boolean done() {
    return done; // done/done() is an odd p5 idiom maintained here
  }
  /** Stop the movie and reset position to the first frame */
  public int reset() {
    try {
      // quicktime, please don't advance time for us,
      // we'll handle that ourselves, thank you very much
      movie.stop();
    } catch(quicktime.QTException ex) {}
    return gotoFirstFrame();
  }
  /**
   * Position the movie at the first frame (frame # zero).
   */
  public int gotoFirstFrame() {
    try {
      movie.setTimeValue(0);
      currentFrameTime = movie.getTime();
      currentFrameNumber = 0;
      done = false;
    } catch(quicktime.QTException ex) {}
    return currentFrameTime;
  }
  /**
   * Position the movie at the last frame (frame # framecount-1).
   */
  public int gotoLastFrame() {
    // easy case: user has precalced frame times
    if (precalcedFrameTimes != null) {
      gotoFrameNumber(precalcedFrameCount-1);
    }
    // otherwise...
    // first of all, we can't just do this:
    //   movie.setTimeValue(movie.getDuration());
    //   step(-1);
    // because then we won't know the frame number.
    // so we have to manually scan all the frames:
    // (user would be better served by precalcing
    //  if they do this more than once!)
    // note to self:  maybe we should just precalc
    // automatically in this case?  since we have
    // to scan all the frames anyway?
    gotoFirstFrame();
    while (!done) step(1);
    done = false; // 'undo' the last overstep that ended the while loop
    return currentFrameTime;
  }
  /**
   * Position the movie at a specified frame.
   * @param desiredFrameNumber Note that this number is zero-based!
   */
  public int gotoFrameNumber(int desiredFrameNumber) {
    // easy way:
    if (precalcedFrameTimes != null) {
      if ((desiredFrameNumber >= 0) && (desiredFrameNumber < precalcedFrameCount)) {
        try {
          currentFrameNumber = desiredFrameNumber;
          currentFrameTime = precalcedFrameTimes[currentFrameNumber];
          movie.setTimeValue(currentFrameTime);
          done = false;
        } catch(quicktime.QTException ex) {}
      } else {
        done = true;
      }
      return currentFrameTime;        
    }
    // hard way:
    done = false;
    while(!done && currentFrameNumber < desiredFrameNumber) step(1);
    while(!done && currentFrameNumber > desiredFrameNumber) step(-1);
    return currentFrameTime;
  }
  /**
   * Step forward one frame.
   */
  public int stepForward() {
    return step(1);
  }
  /**
   * Step forward a specified number of frames.
   */
  public int stepForward(int n) {
    int frametime = currentFrameTime;
    done = false;
    while (!done && n-->0)
      frametime = step(1);
    return frametime;
  }
  /**
   * Step backward one frame.
   */
  public int stepBackward() {
    return step(-1);
  }
  /**
   * Step backward a specified number of frames.
   */
  public int stepBackward(int n) {
    int frametime = currentFrameTime;
    done = false;
    while (!done && n-->0)
      frametime = step(-1);
    return frametime;
  }
  /**
   * Step once in the indicated direction (positive = forward, negative = backward)
   */
  public int step(int dir) {
    // easy way:
    if (precalcedFrameTimes != null) {
      return gotoFrameNumber(currentFrameNumber+dir);
    }
    // hard way:
    try {
      int interestingTimeFlags = quicktime.std.StdQTConstants.nextTimeStep;
      int [] mediaTypes = new int[] {quicktime.std.StdQTConstants.videoMediaType};  
      quicktime.std.movies.TimeInfo timeInfo = movie.getNextInterestingTime(interestingTimeFlags, mediaTypes, currentFrameTime, dir);
      if (timeInfo.time < 0) { // probably -1, movie done
        done = true;
        return currentFrameTime;
      }
      movie.setTimeValue(timeInfo.time);
      currentFrameTime = movie.getTime();
      currentFrameNumber += dir;
      done = false;
    } catch (quicktime.QTException ex) { done=true; }
    return currentFrameTime;
  }
  /**
   * Returns the number of the current frame (zero-based).
   */
  public int getCurrentFrameNumber() { return currentFrameNumber; }
  /**
   * Returns the internal time of the current frame
   */
  public int getCurrentFrameTime() { return currentFrameTime; }
  /**
   * Returns the count of frames in the movie.
   * Note that, as used elsewhere in this class, frame numbers are zero-based,
   * so the frame numbers run from 0..framecount-1.
   */
  public int getFrameCount() {
    if (precalcedFrameTimes != null) {
      return precalcedFrameCount;
    } else {
      // ugh, gotta do it the hard way...
      // save current position
      int savedFrameNumber = currentFrameNumber;
      int savedFrameTime = currentFrameTime;
      // count the frames
      gotoFirstFrame();
      while (!done) step(1);
      done = false;
      int framecount = currentFrameNumber + 1;
      // restore old position
      currentFrameNumber = savedFrameNumber;
      currentFrameTime = savedFrameTime;
      try {
        movie.setTimeValue(currentFrameTime);
      } catch (quicktime.QTException ex) { }
      return framecount;
    }
  }
  @Override public void read() {
    // Movie's built-in read() justs grabs the current time,
    // which is free-running so will "advance" the movie,
    // which we don't want to do, so we've stop()'ed the
    // movie and force our own frame time onto the movie
    // prior to calling super's read()
    try {
      movie.setTimeValue(currentFrameTime);
      super.read();
    } catch (quicktime.QTException ex) {}
  }
}

