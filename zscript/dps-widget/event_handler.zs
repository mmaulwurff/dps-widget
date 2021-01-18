/* Copyright Alexander Kromm (mmaulwurff@gmail.com) 2020
 *
 * This file is part of dps-widget.
 *
 * dps-widget is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version.
 *
 * dps-widget is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * dps-widget.  If not, see <https://www.gnu.org/licenses/>.
 */

class dps_EventHandler : EventHandler
{

  override void worldThingDamaged (WorldEvent event) { registerEvent(event); }
  override void worldLineDamaged  (WorldEvent event) { registerEvent(event); }
  override void worldSectorDamaged(WorldEvent event) { registerEvent(event); }

  override
  void worldTick()
  {
    if (!mIsInitialized)
    {
      initialize();
    }

    mHistory[nextIndex()] = 0;

    if (mShowDps) mDps = damagePerSecond();

    if (level.time % 35 == 0)
    {
      if (mShowMax  .getBool()) mMax = maximum();
      if (mShowAvg  .getBool()) mAverage = average();
      if (mShowTotal.getBool()) mTotal = total();
      if (mShowGraph.getBool())
      {
        updateBarHeights();
      }
    }
  }

  override
  void renderOverlay(RenderEvent event)
  {
    int scale = mScale.getInt();
    int screenWidth  = Screen.getWidth()  / scale;
    int screenHeight = Screen.getHeight() / scale;

    int startX = int(mX.getDouble() * screenWidth);
    int startY = int(mY.getDouble() * screenHeight);

    if (mShowDps  .getBool()) startY += drawDps  (startX, startY, screenWidth, screenHeight);
    if (mShowGraph.getBool()) startY += drawGraph(startX, startY, screenWidth, screenHeight, scale);
    if (mShowMax  .getBool()) startY += drawMax  (startX, startY, screenWidth, screenHeight);
    if (mShowAvg  .getBool()) startY += drawAvg  (startX, startY, screenWidth, screenHeight);
    if (mShowTotal.getBool()) startY += drawTotal(startX, startY, screenWidth, screenHeight);
  }

  override
  void consoleProcess(ConsoleEvent event)
  {
    if (event.name == "dps_clear") clear();
  }

// private: ////////////////////////////////////////////////////////////////////////////////////////

  private
  void registerEvent(WorldEvent event)
  {
    if (event.damageSource == players[consolePlayer].mo)
    {
      mHistory[currentIndex()] += event.damage;
    }
  }

  private play
  void clear() const
  {
    for (uint i = 0; i < HISTORY_SIZE; ++i)
    {
      mHistory[i] = 0;
    }
  }

  private ui
  int drawDps(int startX, int startY, int screenWidth, int screenHeight)
  {
    String dpsString = String.format("%d", mDps);
    return drawText(bigFont, startX, startY, dpsString, screenWidth, screenHeight);
  }

  private ui
  int drawTotal(int startX, int startY, int screenWidth, int screenHeight)
  {
    String totalString = String.format("%s: %d", StringTable.localize("$DPS_TOTAL"), mTotal);
    return drawText(smallFont, startX, startY, totalString, screenWidth, screenHeight);
  }

  private ui
  int drawAvg(int startX, int startY, int screenWidth, int screenHeight)
  {
    String avgString = String.format("%s: %.2f", StringTable.localize("$DPS_AVERAGE"), mAverage);
    return drawText(smallFont, startX, startY, avgString, screenWidth, screenHeight);
  }

  private ui
  int drawMax(int startX, int startY, int screenWidth, int screenHeight)
  {
    String maxString = String.format("%s: %d", StringTable.localize("$DPS_MAX"), mMax);
    return drawText(smallFont, startX, startY, maxString, screenWidth, screenHeight);
  }

  private ui
  int drawGraph(int startX, int startY, int screenWidth, int screenHeight, int scale)
  {
    Color c = mColor.getString();
    double alpha = mAlpha.getDouble();
    int width = mHistorySize.getInt();
    double x = startX + (GRAPH_WIDTH - width) / 2.0;

    // background
    Screen.drawTexture( mTexture
                      , NO_ANIMATION
                      , x
                      , startY
                      , DTA_FillColor     , c
                      , DTA_AlphaChannel  , true
                      , DTA_Alpha         , alpha
                      , DTA_VirtualWidth  , screenWidth
                      , DTA_VirtualHeight , screenHeight
                      , DTA_DestWidth     , width
                      , DTA_DestHeight    , GRAPH_HEIGHT
                      , DTA_KeepRatio     , true
                      );

    for (uint i = HISTORY_SECONDS - width; i < HISTORY_SECONDS; ++i)
    {
      if (mBarHeights[i] == 0) continue;

      Screen.drawTexture( mTexture
                        , NO_ANIMATION
                        , i + x - HISTORY_SECONDS + width
                        , startY + GRAPH_HEIGHT - mBarHeights[i]
                        , DTA_FillColor     , c
                        , DTA_Alpha         , alpha
                        , DTA_VirtualWidth  , screenWidth
                        , DTA_VirtualHeight , screenHeight
                        , DTA_ClipBottom    , int(startY + GRAPH_HEIGHT) * scale
                        , DTA_ClipTop       , startY * scale
                        , DTA_KeepRatio     , true
                        );
    }

    return GRAPH_HEIGHT + 1;
  }

  private ui
  int drawText(Font aFont, int x, int y, String aString, int screenWidth, int screenHeight)
  {
    int width = aFont.stringWidth(aString);
    Screen.drawText( aFont
                   , Font.CR_WHITE
                   , x + (GRAPH_WIDTH - width) / 2
                   , y
                   , aString
                   , DTA_VirtualWidth  , screenWidth
                   , DTA_VirtualHeight , screenHeight
                   , DTA_KeepRatio     , true
                   );

    return aFont.getHeight();
  }

  private
  void initialize()
  {
    mIsInitialized = true;

    mTexture = TexMan.checkForTexture("dps_tex", TexMan.Type_Any);

    mColor = dps_Cvar.from("dps_color");
    mAlpha = dps_Cvar.from("dps_alpha");
    mScale = dps_Cvar.from("dps_scale");
    mX     = dps_Cvar.from("dps_x");
    mY     = dps_Cvar.from("dps_y");
    mHistorySize = dps_Cvar.from("dps_history");

    mShowDps   = dps_Cvar.from("dps_show_dps");
    mShowGraph = dps_Cvar.from("dps_show_graph");
    mShowMax   = dps_Cvar.from("dps_show_max");
    mShowAvg   = dps_Cvar.from("dps_show_avg");
    mShowTotal = dps_Cvar.from("dps_show_total");
  }

  private
  int damagePerSecond() const
  {
    int result = 0;
    for (int i = 0; i < TICRATE; ++i)
    {
      int index = makeIndex(-i);
      result += mHistory[index];
    }
    return result;
  }

  private
  int total() const
  {
    int result = 0;
    uint end = mHistorySize.getInt() * TICRATE;
    for (uint i = 0; i < end; ++i)
    {
      result += mHistory[makeIndex(-i)];
    }
    return result;
  }

  private
  int maximum() const
  {
    int max = 0;
    uint end = mHistorySize.getInt() * TICRATE - TICRATE;
    for (uint i = 0; i < end; ++i)
    {
      int localSum = 0;
      for (int j = 0; j < TICRATE; ++j)
      {
        // makeIndex inlined here for better performance.
        int index = (level.time - i - j + HISTORY_SIZE) % HISTORY_SIZE;
        localSum += mHistory[index];
      }

      max = max(max, localSum);
    }

    return max;
  }

  private
  double average() const
  {
    double sum = 0;
    uint end = mHistorySize.getInt() * TICRATE;
    for (int i = 0; i < end; ++i)
    {
      sum += mHistory[makeIndex(-i)];
    }
    return sum * TICRATE / HISTORY_SIZE;
  }

  private
  int maximumSeparated() const
  {
    int result = 0;

    int start = HISTORY_SECONDS - mHistorySize.getInt();
    for (int i = start; i < HISTORY_SECONDS; ++i)
    {
      int localSum = 0;
      for (int j = 0; j < TICRATE; ++j)
      {
        int index = makeIndex(i * TICRATE + j - HISTORY_SIZE + 1);
        localSum += mHistory[index];
      }
      result = max(result, localSum);
    }

    return result;
  }

  private
  void updateBarHeights()
  {
    int maxSeparated = maximumSeparated();

    int start = HISTORY_SECONDS - mHistorySize.getInt();
    for (int i = start; i < HISTORY_SECONDS; ++i)
    {
      mBarHeights[i] = 0;

      if (maxSeparated == 0) continue;

      for (int j = 0; j < TICRATE; ++j)
      {
        int index = makeIndex(i * TICRATE + j - HISTORY_SIZE + 1);
        mBarHeights[i] += mHistory[index];
      }
      mBarHeights[i] = mBarHeights[i] * GRAPH_HEIGHT / maxSeparated;
    }
  }

  private
  int makeIndex(int offset) const
  {
    return (level.time + offset + HISTORY_SIZE) % HISTORY_SIZE;
  }

  private int nextIndex()    const { return makeIndex(1); }
  private int currentIndex() const { return makeIndex(0); }

  const NO_ANIMATION = 0; // == false

  const HISTORY_SECONDS = 60;
  const GRAPH_HEIGHT = 30;
  const GRAPH_WIDTH  = HISTORY_SECONDS;
  const HISTORY_SIZE = HISTORY_SECONDS * TICRATE;

  private int mHistory[HISTORY_SIZE];
  private int mBarHeights[HISTORY_SECONDS];

  private bool mIsInitialized;

  private TextureID mTexture;

  private dps_Cvar mColor;
  private dps_Cvar mAlpha;
  private dps_Cvar mScale;
  private dps_Cvar mX;
  private dps_Cvar mY;
  private dps_Cvar mHistorySize;

  private dps_Cvar mShowDps;
  private dps_Cvar mShowGraph;
  private dps_Cvar mShowMax;
  private dps_Cvar mShowAvg;
  private dps_Cvar mShowTotal;

  private int mDps;
  private int mMax;
  private double mAverage;
  private int mTotal;

} // class dps_EventHandler
