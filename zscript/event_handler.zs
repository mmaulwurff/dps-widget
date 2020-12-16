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
    Color c = mColor.getString();
    double alpha = mAlpha.getDouble();

    int scale = mScale.getInt();
    int screenWidth  = Screen.getWidth()  / scale;
    int screenHeight = Screen.getHeight() / scale;

    int startX = int(mX.getDouble() * screenWidth);
    int startY = int(mY.getDouble() * screenHeight);

    Screen.drawTexture( mBackground
                      , NO_ANIMATION
                      , startX
                      , startY
                      , DTA_FillColor     , c
                      , DTA_AlphaChannel  , true
                      , DTA_Alpha         , alpha
                      , DTA_VirtualWidth  , screenWidth
                      , DTA_VirtualHeight , screenHeight
                      , DTA_DestWidth     , GRAPH_WIDTH - 1
                      , DTA_DestHeight    , GRAPH_HEIGHT
                      , DTA_KeepRatio     , true
                      );

    Font bigFont   = Font.getFont("BIGFONT");
    Font smallFont = Font.getFont("SMALLFONT");
    int bigTextHeight = bigFont.getHeight();

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
                        , startX + i
                        , startY + GRAPH_HEIGHT - height
                        , DTA_FillColor     , c
                        , DTA_Alpha         , alpha
                        , DTA_VirtualWidth  , screenWidth
                        , DTA_VirtualHeight , screenHeight
                        , DTA_ClipBottom    , int(startY + GRAPH_HEIGHT) * scale
                        , DTA_KeepRatio     , true
                        );
    }

    String dps = String.format("%d", damagePerSecond());
    int dpsWidth = bigFont.stringWidth(dps);
    Screen.drawText( bigFont
                   , Font.CR_WHITE
                   , startX + (GRAPH_WIDTH - dpsWidth) / 2
                   , startY - bigTextHeight
                   , dps
                   , DTA_VirtualWidth  , screenWidth
                   , DTA_VirtualHeight , screenHeight
                   , DTA_KeepRatio     , true
                   );

    String maxString = String.format("%s: %d", StringTable.localize("$DPS_MAX"), max);
    int maxWidth = smallFont.stringWidth(maxString);

    Screen.drawText( smallFont
                   , Font.CR_WHITE
                   , startX + (GRAPH_WIDTH - maxWidth) / 2
                   , startY + GRAPH_HEIGHT
                   , maxString
                   , DTA_VirtualWidth  , screenWidth
                   , DTA_VirtualHeight , screenHeight
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

  const HISTORY_SECONDS = 60;
  const NO_ANIMATION = 0; // == false
  const GRAPH_HEIGHT = 30;
  const GRAPH_WIDTH  = 60;

  private int mDamagePerTic[TICRATE];
  private int mHistory[HISTORY_SECONDS];

  private bool mIsInitialized;

  private TextureID mBackground;
  private TextureID mColumn;

  private dps_Cvar mColor;
  private dps_Cvar mAlpha;
  private dps_Cvar mScale;
  private dps_Cvar mX;
  private dps_Cvar mY;

} // class dps_EventHandler
