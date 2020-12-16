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

/**
 * This class provides access to a user or server Cvar.
 *
 * Accessing Cvars through this class is faster because calling Cvar.GetCvar()
 * is costly. This class caches the result of Cvar.GetCvar() and handles
 * loading a savegame.
 */
class dps_Cvar
{

  static
  dps_Cvar from(string name)
  {
    let result = new("dps_Cvar");

    result.mName = name;
    result.mCvar = NULL;
    result.load();

    return result;
  }

  string getString() { load(); return mCvar.getString(); }
  bool   getBool()   { load(); return mCvar.getInt();    }
  int    getInt()    { load(); return mCvar.getInt();    }
  double getDouble() { load(); return mCvar.getFloat();  }

// private: ////////////////////////////////////////////////////////////////////////////////////////

  private
  void load()
  {
    if (isLoaded()) return;

    mCvar = Cvar.GetCvar(mName, players[consolePlayer]);

    if (!isLoaded())
    {
      Console.printf("[dps-widget]: cvar %s not found.", mName);
    }
  }

  private
  bool isLoaded() const
  {
    return (mCvar != NULL);
  }

  private string         mName;
  private transient Cvar mCvar;

} // class dps_Cvar
