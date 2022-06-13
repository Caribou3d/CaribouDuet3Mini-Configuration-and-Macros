#!/bin/sh

# =========================================================================================================
# definition for Caribou320 Duet3Mini5+ Bondtech - SE HT Thermistor - BL-Touch Left
# =========================================================================================================

CARIBOU_VARIANT="Caribou320 Duet3Mini5+ Bondtech - SE HT Thermistor - BL-Touch Left"
CARIBOU_NAME="Caribou320-HBLL"
CARIBOU_ZHEIGHTLEVELING="Z305"
CARIBOU_ZHEIGHT="Z316.50"
CARIBOU_EESTEPS=830.00
CARIBOU_INITIALLOAD=90
CARIBOU_FINALUNLOAD=95
CARIBOU_MINEXTRUDETEMP=180
CARIBOU_MINRETRACTTEMP=180

# set output for sys and macros
#

SysOutputPath=../processed
# prepare output folder
if [ ! -d "$SysOutputPath" ]; then
    mkdir -p $SysOutputPath || exit 27
else
    rm -fr $SysOutputPath || exit 27
    mkdir -p $SysOutputPath || exit 27
fi

MacrosDir=../../macros
MacroOutputPath=$MacrosDir/processed
# prepare output folder
if [ ! -d "$MacroOutputPath" ]; then
    mkdir -p $MacroOutputPath || exit 27
else
    rm -fr $MacroOutputPath || exit 27
    mkdir -p $MacroOutputPath || exit 27
fi

# =========================================================================================================
# create sys files
# =========================================================================================================

# copy sys files to processed folder
find .. -maxdepth 1 -type f -exec cp -rt $SysOutputPath {} +
cp -r ../00-Functions $SysOutputPath

#
# create bed.g
#

sed "
{s/#CARIBOU_VARIANT/$CARIBOU_VARIANT/};
{s/G30 P0 X25 Y105 Z-99999/G30 P0 X10 Y105 Z-99999/};
{s/G30 P1 X240 Y105 Z-99999 S2/G30 P1 X225 Y105 Z-99999 S2/};
{/#CARIBOU_ZPROBERESET/ c\
M558 F400 T8000 A1 S0.03                                               ; for BL-Touch
};
" < ../bed.g > $SysOutputPath/bed.g

#
# create config.g
#

# general replacements
sed "
{s/#CARIBOU_VARIANT/$CARIBOU_VARIANT/};
{s/#CARIBOU_NAME/$CARIBOU_NAME/};
{s/#CARIBOU_ZHEIGHT/$CARIBOU_ZHEIGHT/};
{s/#CARIBOU_EESTEPS/$CARIBOU_EESTEPS/};
{s/#CARIBOU_MINEXTRUDETEMP/$CARIBOU_MINEXTRUDETEMP/};
{s/#CARIBOU_MINRETRACTTEMP/$CARIBOU_MINRETRACTTEMP/};
" < ../config.g > $SysOutputPath/config.g

# replacements for motor currents
sed -i "
{/#CARIBOU_MOTOR_CURRENTS/ c\
M906 X1250 Y1250 Z650 E900 I40                                         ; set motor currents (mA) and motoridle factor in percent
};
" $SysOutputPath/config.g

# replacemente SE thermistor
sed -i "
{/#CARIBOU_HOTEND_THERMISTOR/ c\
; Hotend (Mosquito or Mosquito Magnum with SE Thermistor) \\
;\\
M308 S1 P\"temp1\" Y\"thermistor\" T500000 B4723 C1.19622e-7 A\"Nozzle\"   ; SE configure sensor 0 as thermistor on pin e0temp\\
;\\
M950 H1 C\"out1\" T1                                                     ; create nozzle heater output on e0heat and map it to sensor 1\\
M307 H1 B0 S1.00                                                       ; disable bang-bang mode for heater 1 and set PWM limit\\
M143 H1 S365                                                           ; set temperature limit for heater 1 to 365°C
};
" $SysOutputPath/config.g

# replacements for BL-Touch
sed -i "
{/#CARIBOU_ZPROBE/ c\
; BL-Touch Left \\
;\\
M950 S0 C\"io1.out\"                                     ; sensor for BL-Touch\\
M558 P9 C\"^io1.in\" H2.5 F400 T8000 A1 S0.03            ; for BL-Touch\\
M557 X10:220 Y1:176 P7                                                 ; define mesh grid
};
{/#CARIBOU_OFFSETS/ c\
G31 X-24.3 Y-34.1
}
" $SysOutputPath/config.g

#
# create homez and homeall
#

sed "
{s/#CARIBOU_VARIANT/$CARIBOU_VARIANT/};
{s/#CARIBOU_MEASUREPOINT/G1 X148.5 Y142.5 F3600                                 ; go to center of the bed/};
{/#CARIBOU_ZPROBE/ c\
M280 P0 S160                                                           ; BLTouch, alarm release\\
G4 P100                                                                ; BLTouch, delay for the release command
};
" < ../homez.g > $SysOutputPath/homez.g

sed "
{s/#CARIBOU_VARIANT/$CARIBOU_VARIANT/};
{/#CARIBOU_ZPROBE/ c\
M280 P0 S160                                                           ; BLTouch, alarm release\\
G4 P100                                                                ; BLTouch, delay for the release command
};
" < ../start.g > $SysOutputPath/start.g

#
# create trigger2.g
#

sed "
{s/#CARIBOU_MINEXTRUDETEMP/$CARIBOU_MINEXTRUDETEMP/};
{s/#CARIBOU_MINRETRACTTEMP/$CARIBOU_MINRETRACTTEMP/};
{s/#CARIBOU_INITIALLOAD/$CARIBOU_INITIALLOAD/g}
" < ../trigger2.g > $SysOutputPath/trigger2.g

# =========================================================================================================
# create macro files
# =========================================================================================================

# copy macros directory to processed folder
find $MacrosDir/* -maxdepth 0  ! \( -name "*Main*" -o -name "*Preheat*" -o -name "*processed*"  \) -exec cp -r -t  $MacroOutputPath {} \+

mkdir $MacroOutputPath/04-Maintenance
find $MacrosDir/04-Maintenance/* -maxdepth 0  ! \( -name "*First*" \) -exec cp -r -t  $MacroOutputPath/04-Maintenance {} \+
cp -r $MacrosDir/04-Maintenance/01-First_Layer_Calibration/processed $MacroOutputPath/04-Maintenance/01-First_Layer_Calibration
cp -r $MacrosDir/00-Preheat_Extruder/processed $MacroOutputPath/00-Preheat_Extruder

# create 00-Test_Homing
#
sed "
{s/#CARIBOU_VARIANT/$CARIBOU_VARIANT/};
{s/#CARIBOU_MEASUREPOINT/G1 X148.5 Y142.5 F3600            ; go to center of the bed/};
{/#CARIBOU_ZPROBE/ c\
M280 P0 S160                      ; BLTouch, alarm release\\
G4 P100                           ; BLTouch, delay for the release command
};
" < $MacrosDir/04-Maintenance/00-Self_Tests/00-Test_Homing > $MacroOutputPath/04-Maintenance/00-Self_Tests/00-Test_Homing

# create 01-Level-X-Axis
#
sed "
{s/#CARIBOU_VARIANT/$CARIBOU_VARIANT/};
{s/#CARIBOU_NAME/$CARIBOU_NAME/};
{s/#CARIBOU_ZHEIGHTLEVELING/$CARIBOU_ZHEIGHTLEVELING/}
{s/#CARIBOU_ZHEIGHT/$CARIBOU_ZHEIGHT/}
" < $MacrosDir/04-Maintenance/00-Self_Tests/01-Level_X-Axis > $MacroOutputPath/04-Maintenance/00-Self_Tests/01-Level_X-Axis

# create Load_Filament
#
sed "
{s/#CARIBOU_VARIANT/$CARIBOU_VARIANT/};
{s/#CARIBOU_MINEXTRUDETEMP/$CARIBOU_MINEXTRUDETEMP/};
{s/#CARIBOU_MINRETRACTTEMP/$CARIBOU_MINRETRACTTEMP/};
{s/#CARIBOU_INITIALLOAD/$CARIBOU_INITIALLOAD/g}
" < $MacrosDir/01-Filament_Handling/00-Load_Filament > $MacroOutputPath/01-Filament_Handling/00-Load_Filament

# create Unload_Filament
#
sed "
{s/#CARIBOU_VARIANT/$CARIBOU_VARIANT/};
{s/#CARIBOU_MINEXTRUDETEMP/$CARIBOU_MINEXTRUDETEMP/};
{s/#CARIBOU_MINRETRACTTEMP/$CARIBOU_MINRETRACTTEMP/};
{s/#CARIBOU_FINALUNLOAD/$CARIBOU_FINALUNLOAD/g}
" < $MacrosDir/01-Filament_Handling/01-Unload_Filament > $MacroOutputPath/01-Filament_Handling/01-Unload_Filament

# create Change_Filament
#
sed "
{s/#CARIBOU_VARIANT/$CARIBOU_VARIANT/};
{s/#CARIBOU_MINEXTRUDETEMP/$CARIBOU_MINEXTRUDETEMP/};
{s/#CARIBOU_MINRETRACTTEMP/$CARIBOU_MINRETRACTTEMP/};
{s/#CARIBOU_INITIALLOAD/$CARIBOU_INITIALLOAD/g}
{s/#CARIBOU_FINALUNLOAD/$CARIBOU_FINALUNLOAD/g}
" < $MacrosDir/01-Filament_Handling/03-Change_Filament > $MacroOutputPath/01-Filament_Handling/03-Change_Filament

# =========================================================================================================
