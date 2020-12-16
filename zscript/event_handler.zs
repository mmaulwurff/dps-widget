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
      mHistory[currentHistoryIndex()] = damagePerSecond();
    }
  }

  override
  void renderOverlay(RenderEvent event)
  {
    vector2 start = (50, 50);
    Color c = mColor.getString();

    int mScale = 1;
    int mScreenWidth  = Screen.getWidth()  / mScale;
    int mScreenHeight = Screen.getHeight() / mScale;

    Screen.drawTexture( mBackground
                      , NO_ANIMATION
                      , start.x
                      , start.y
                      , DTA_FillColor     , c
                      , DTA_AlphaChannel  , true
                      , DTA_Alpha         , 0.5
                      , DTA_VirtualWidth  , mScreenWidth
                      , DTA_VirtualHeight , mScreenHeight
                      , DTA_DestWidth     , GRAPH_WIDTH - 1
                      , DTA_DestHeight    , GRAPH_HEIGHT
                      , DTA_KeepRatio     , true
                      );

    int currentHistoryIndex = nextHistoryIndex();
    int max = maxInHistory();
    for (uint i = 0; i < HISTORY_SECONDS - 1; ++i)
    {
      int index  = (i + currentHistoryIndex) % HISTORY_SECONDS;
      int height = max
        ? GRAPH_HEIGHT * mHistory[index] / max
        : 0;

      Screen.drawTexture( mColumn
                        , NO_ANIMATION
                        , start.x + i
                        , start.y + GRAPH_HEIGHT - height
                        , DTA_FillColor     , c
                        , DTA_AlphaChannel  , true
                        , DTA_Alpha         , 0.5
                        , DTA_VirtualWidth  , mScreenWidth
                        , DTA_VirtualHeight , mScreenHeight
                        , DTA_ClipBottom    , int(start.y + GRAPH_HEIGHT)
                        , DTA_KeepRatio     , true
                        );
    }

    String dps = String.format("%d", damagePerSecond());
    int dpsWidth = mBigFont.stringWidth(dps);
    Screen.drawText( mBigFont
                   , Font.CR_WHITE
                   , start.x + (GRAPH_WIDTH - dpsWidth) / 2
                   , start.y - mBigTextHeight
                   , dps
                   , DTA_VirtualWidth  , mScreenWidth
                   , DTA_VirtualHeight , mScreenHeight
                   , DTA_KeepRatio     , true
                   );

    String maxString = String.format("%s: %d", StringTable.localize("$DPS_MAX"), max);
    int maxWidth = mSmallFont.stringWidth(maxString);

    Screen.drawText( mSmallFont
                   , Font.CR_WHITE
                   , start.x + (GRAPH_WIDTH - maxWidth) / 2
                   , start.y + GRAPH_HEIGHT
                   , maxString
                   , DTA_VirtualWidth  , mScreenWidth
                   , DTA_VirtualHeight , mScreenHeight
                   , DTA_KeepRatio     , true
                   );
  }

// private: ////////////////////////////////////////////////////////////////////////////////////////

  private
  void initialize()
  {
    mIsInitialized = true;

    mBackground = TexMan.checkForTexture("dps_back", TexMan.Type_Any);
    mColumn     = TexMan.checkForTexture("dps_col", TexMan.Type_Any);

    mBigFont   = Font.getFont("BIGFONT");
    mSmallFont = Font.getFont("SMALLFONT");
    mBigTextHeight = mBigFont.getHeight();

    mColor = dps_Cvar.from("dps_color");
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

  const HISTORY_SECONDS = 60;
  const NO_ANIMATION = 0; // == false
  const GRAPH_HEIGHT = 30;
  const GRAPH_WIDTH  = 60;

  private int mDamagePerTic[TICRATE];
  private int mHistory[HISTORY_SECONDS];

  private bool mIsInitialized;

  private TextureID mBackground;
  private TextureID mColumn;

  private Font mBigFont;
  private Font mSmallFont;
  private int  mBigTextHeight;

  private dps_Cvar mColor;

} // class dps_EventHandler
