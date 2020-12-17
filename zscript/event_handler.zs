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

  override
  void worldThingDamaged(WorldEvent event)
  {
    if (event.damageSource == players[consolePlayer].mo)
    {
      mDamagePerTic[currentDamageIndex()] += event.damage;
    }
  }

  override
  void worldTick()
  {
    if (!mIsInitialized)
    {
      initialize();
    }

    mDamagePerTic[nextDamageIndex()] = 0;
    if (level.time % 35 == 0)
    {
      setHistory(currentHistoryIndex(), damagePerSecond());
    }

    mScaleInt = mScale.getInt();
    mScreenWidth  = Screen.getWidth()  / mScaleInt;
    mScreenHeight = Screen.getHeight() / mScaleInt;
  }

  override
  void renderOverlay(RenderEvent event)
  {
    // prevent flickering when rendering happens before world tick.
    if (level.time % 35 == 0)
    {
      setHistory(currentHistoryIndex(), damagePerSecond());
    }

    int startX = int(mX.getDouble() * mScreenWidth);
    int startY = int(mY.getDouble() * mScreenHeight);

    startY += drawText(bigFont, startX, startY, String.format("%d", damagePerSecond()));

    if (mShowGraph.getBool()) startY += drawGraph(startX, startY);
    if (mShowMax  .getBool()) startY += drawMax  (startX, startY);
    if (mShowAvg  .getBool()) startY += drawAvg  (startX, startY);
    if (mShowTotal.getBool()) startY += drawTotal(startX, startY);
  }

// private: ////////////////////////////////////////////////////////////////////////////////////////

  private ui
  int drawTotal(int startX, int startY)
  {
    double total = totalInHistory();
    String totalString = String.format("%s: %d", StringTable.localize("$DPS_TOTAL"), total);
    return drawText(smallFont, startX, startY, totalString);
  }

  private ui
  int drawAvg(int startX, int startY)
  {
    double average = averageInHistory();
    String avgString = String.format("%s: %.2f", StringTable.localize("$DPS_AVERAGE"), average);
    return drawText(smallFont, startX, startY, avgString);
  }

  private ui
  int drawMax(int startX, int startY)
  {
    int max = maxInHistory();
    String maxString = String.format("%s: %d", StringTable.localize("$DPS_MAX"), max);
    return drawText(smallFont, startX, startY, maxString);
  }

  private ui
  int drawGraph(int startX, int startY)
  {
    Color c = mColor.getString();
    double alpha = mAlpha.getDouble();

    Screen.drawTexture( mTexture
                      , NO_ANIMATION
                      , startX
                      , startY
                      , DTA_FillColor     , c
                      , DTA_AlphaChannel  , true
                      , DTA_Alpha         , alpha
                      , DTA_VirtualWidth  , mScreenWidth
                      , DTA_VirtualHeight , mScreenHeight
                      , DTA_DestWidth     , GRAPH_WIDTH
                      , DTA_DestHeight    , GRAPH_HEIGHT
                      , DTA_KeepRatio     , true
                      );

    int max = maxInHistory();
    int nextHistoryIndex = nextHistoryIndex();
    for (uint i = 0; i < HISTORY_SECONDS; ++i)
    {
      int index  = (i + nextHistoryIndex) % HISTORY_SECONDS;
      int height = max
        ? GRAPH_HEIGHT * mHistory[index] / max
        : 0;

      if (height == 0) continue;

      Screen.drawTexture( mTexture
                        , NO_ANIMATION
                        , startX + i
                        , startY + GRAPH_HEIGHT - height
                        , DTA_FillColor     , c
                        , DTA_Alpha         , alpha
                        , DTA_VirtualWidth  , mScreenWidth
                        , DTA_VirtualHeight , mScreenHeight
                        , DTA_ClipBottom    , int(startY + GRAPH_HEIGHT) * mScaleInt
                        , DTA_KeepRatio     , true
                        );
    }

    return GRAPH_HEIGHT;
  }

  private ui
  int drawText(Font aFont, int x, int y, String aString)
  {
    int width = aFont.stringWidth(aString);
    Screen.drawText( aFont
                   , Font.CR_WHITE
                   , x + (GRAPH_WIDTH - width) / 2
                   , y
                   , aString
                   , DTA_VirtualWidth  , mScreenWidth
                   , DTA_VirtualHeight , mScreenHeight
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

    mShowGraph = dps_Cvar.from("dps_show_graph");
    mShowMax   = dps_Cvar.from("dps_show_max");
    mShowAvg   = dps_Cvar.from("dps_show_avg");
    mShowTotal = dps_Cvar.from("dps_show_total");
  }

  private int currentHistoryIndex() const { return ((level.time / TICRATE) % HISTORY_SECONDS); }
  private int nextHistoryIndex() const { return (((level.time / TICRATE) + 1) % HISTORY_SECONDS); }

  private
  int maxInHistory() const
  {
    int result = 0;
    for (uint i = 0; i < HISTORY_SECONDS; ++i)
    {
      result = max(mHistory[i], result);
    }
    return result;
  }

  private
  int totalInHistory() const
  {
    int result = 0;
    for (uint i = 0; i < HISTORY_SECONDS; ++i)
    {
      result += mHistory[i];
    }
    return result;
  }

  private
  double averageInHistory() const
  {
    return double(totalInHistory()) / HISTORY_SECONDS;
  }

  private play
  void setHistory(int index, int value) const
  {
    mHistory[index] = value;
  }

  private int currentDamageIndex() const { return ( level.time      % TICRATE); }
  private int nextDamageIndex()    const { return ((level.time + 1) % TICRATE); }

  private
  int damagePerSecond() const
  {
    int result = 0;
    for (uint i = 0; i < TICRATE; ++i)
    {
      result += mDamagePerTic[i];
    }
    return result;
  }

  const NO_ANIMATION = 0; // == false

  const HISTORY_SECONDS = 60;
  const GRAPH_HEIGHT = 30;
  const GRAPH_WIDTH  = HISTORY_SECONDS;

  private int mDamagePerTic[TICRATE];
  private int mHistory[HISTORY_SECONDS];

  private bool mIsInitialized;

  private TextureID mTexture;

  private dps_Cvar mColor;
  private dps_Cvar mAlpha;
  private dps_Cvar mScale;
  private dps_Cvar mX;
  private dps_Cvar mY;
  private dps_Cvar mShowGraph;
  private dps_Cvar mShowMax;
  private dps_Cvar mShowAvg;
  private dps_Cvar mShowTotal;

  private int mScaleInt;
  private int mScreenWidth;
  private int mScreenHeight;

} // class dps_EventHandler
