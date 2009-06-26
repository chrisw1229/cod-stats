main() {
  //only call if you want HUD scores
  thread hudScores();
}

playSoundinSpace (alias, origin)
{
	org = spawn ("script_model",origin);
	org playsound (alias);
	wait 8;
	org delete();
}

printDebug (text) {
  if (getcvar("scr_cnq_debug") == "1" ) {
    iprintln ("DEBUG: " + text);
  }
}

///////////////////////////////////////////////////////////////////////////////
// Convert uppercase characters in a string to lowercase
// CODE COURTESY OF [MC]HAMMER's CODADM
toLower( str ) {
	return ( mapChar( str, "U-L" ) );
}

//
///////////////////////////////////////////////////////////////////////////////
// Convert lowercase characters in a string to uppercase
// CODE COURTESY OF [MC]HAMMER's CODADM
toUpper( str ) {
	return ( mapChar( str, "L-U" ) );
}

///////////////////////////////////////////////////////////////////////////////
// PURPOSE: 	Convert (map) characters in a string to another character.  A
//		conversion parameter determines how to perform the mapping.
// RETURN:	Mapped string
// CALL:	<str> = waitthread level.ham_f_utils::mapChar <str> <str>
// CODE COURTESY OF [MC]HAMMER's CODADM
mapChar( str, conv )
{
	if ( !isdefined( str ) || ( str == "" ) )
		return ( "" );

	switch ( conv )
	{
	  case "U-L":	case "U-l":	case "u-L":	case "u-l":
		from = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
		to   = "abcdefghijklmnopqrstuvwxyz";
		break;
	  case "L-U":	case "L-u":	case "l-U":	case "l-u":
		from = "abcdefghijklmnopqrstuvwxyz";
		to   = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
		break;
	  default:
	  	return ( str );
	}

	s = "";
	for ( i = 0; i < str.size; i++ )
	{
		ch = str[ i ];

		for ( j = 0; j < from.size; j++ )
			if ( ch == from[ j ] )
			{
				ch = to[ j ];
				break;
			}

		s += ch;
	}

	return ( s );
}

hudScores() {

	level endon( "end_map" );
	for (;;) {
		showHudScores();
		wait 1;
	}  
}

///////////////////////////////////////////////////////////////////////////////
// Display team score on HUD
// CODE LARGELY COURTESY OF [MC]HAMMER's CODADM
showHudScores() {

	teams = [];
	teams[ 0 ] = game["attackers"];
	teams[ 1 ] = game["defenders"];

	_pos = 0;
	for ( i = 0; i < teams.size; i++ )
	{
		if ( !isdefined( level._team_score ) ||
		     !isdefined( level._team_score[ _pos ] ) )
		{
			_s = newHudElem();
			_s.x = 639;
			_s.y = 25 + _pos * 14;
			_s.alignX = "right";
			_s.alignY = "middle";
			_s.sort = 10;
			_s.color = ( 1, 1, 0 );
			_s.fontScale = 1;

			level._team_score[ _pos ] = _s;
		}
		else
			_s = level._team_score[ _pos ];

		if ( !isdefined( level._team_icon ) ||
		     !isdefined( level._team_icon[ _pos ] ) )		{

			_i = newHudElem();
			_i.x = 610;
			_i.y = 21 + _pos * 14;
			_i.alignX = "center";
			_i.alignY = "top";
			_i.sort = 1;

			level._team_icon[ _pos ] = _i;
		} else
			_i = level._team_icon[ _pos ];

		_team = teams[ i ];
		if (isdefined(_team)) {
	        _score = getTeamScore(_team);
    
 			_i setShader( game[ "headicon_" + _team ], 12, 12 );
			_s setValue( _score );

			_pos++;  
		}
  }

	return;
}

//**********************************************************************************************
	// Modified/Added by Wizard220

// PURPOSE: Removes color changes in a string.
monotone( str )
{
	if ( !isdefined( str ) || ( str == "" ) )
		return ( "" );

	_s = "";

	_colorCheck = false;
	for ( i = 0; i < str.size; i++ )
	{
		ch = str[ i ];
		if ( _colorCheck )
		{
			_colorCheck = false;

			switch ( ch )
			{
			  case "0":	// black
			  case "1":	// red
			  case "2":	// green
			  case "3":	// yellow
			  case "4":	// blue
			  case "5":	// cyan
			  case "6":	// pink
			  case "7":	// white
			  case "8":	// Olive
			  case "9":	// Grey
			  	break;
			  default:
			  	_s += ( "^" + ch );
			  	break;
			}
		}
		else if ( ch == "^" )
			_colorCheck = true;
		else
			_s += ch;
	}


	return ( _s );
}
//**********************************************************************************************
