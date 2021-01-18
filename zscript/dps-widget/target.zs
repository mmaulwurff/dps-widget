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

class dps_Target : Actor
{

  Default
  {
    Radius 25;
    Height 50;
    Health 5;
    Tag "Target";

    +Solid;
    +Shootable;
    +NoBlood;
    +IsMonster;
    -CountKill;
  }

  States
  {
  Spawn:
    dpst B -1;
    stop;
  }

  override
  void die(Actor source, Actor inflictor, int dmgflags, name meansOfDeath)
  {
    if (meansOfDeath == "Massacre")
    {
      super.die(source, inflictor, dmgflags, meansOfDeath);
    }
    else
    {
      a_SetHealth(getSpawnHealth());
    }
  }

} // class dps_Target
