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

    mScaleInt = mScale.getInt();
    mScreenWidth  = Screen.getWidth()  / mScaleInt;
    mScreenHeight = Screen.getHeight() / mScaleInt;
  }

  override
  void renderOverlay(RenderEvent event)
  {
    if (level.time % 35 == 0)
    {
      setHistory(currentHistoryIndex(), damagePerSecond());
    }

    Color c = mColor.getString();
    double alpha = mAlpha.getDouble();

    int startX = int(mX.getDouble() * mScreenWidth);
    int startY = int(mY.getDouble() * mScreenHeight);

    startY += drawText(bigFont, startX, startY, String.format("%d", damagePerSecond()));

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

    int nextHistoryIndex = nextHistoryIndex();
    int max = maxInHistory();
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

    startY += GRAPH_HEIGHT;

    String maxString = String.format("%s: %d", StringTable.localize("$DPS_MAX"), max);
    startY += drawText(smallFont, startX, startY, maxString);

    double average = averageInHistory();
    String avgString = String.format("%s: %.2f", StringTable.localize("$DPS_AVERAGE"), average);
    startY += drawText(smallFont, startX, startY, avgString);
  }

// private: ////////////////////////////////////////////////////////////////////////////////////////

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
  double averageInHistory() const
  {
    int sum = 0;
    for (uint i = 0; i < HISTORY_SECONDS; ++i)
    {
      sum += mHistory[i];
    }
    double result = double(sum) / HISTORY_SECONDS;
    return result;
  }

  const HISTORY_SECONDS = 60;
  const NO_ANIMATION = 0; // == false
  const GRAPH_HEIGHT = 30;
  const GRAPH_WIDTH  = 60;

  private play
  void setHistory(int index, int value) const
  {
    mHistory[index] = value;
  }

  private int mDamagePerTic[TICRATE];
  private int mHistory[HISTORY_SECONDS];

  private bool mIsInitialized;

  private TextureID mTexture;

  private dps_Cvar mColor;
  private dps_Cvar mAlpha;
  private dps_Cvar mScale;
  private dps_Cvar mX;
  private dps_Cvar mY;

  private int mScaleInt;
  private int mScreenWidth;
  private int mScreenHeight;

} // class dps_EventHandler
