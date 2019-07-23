## \file Calculations.py
from __future__ import print_function
import sys
import math

import InputParameters

## \brief Calculates flight duration
# \param inParams No description given
def func_t_flight(inParams):
    return ((2 * (inParams.v_launch * math.sin(inParams.angle))) / 9.8)

## \brief Calculates landing position
# \param inParams No description given
def func_p_land(inParams):
    return ((2 * ((inParams.v_launch ** 2) * (math.sin(inParams.angle) * math.cos(inParams.angle)))) / 9.8)

## \brief Calculates distance between the target position and the landing position
# \param inParams No description given
# \param p_land landing position
def func_d_offset(inParams, p_land):
    return (p_land - inParams.p_target)

## \brief Calculates output message as a string
# \param inParams No description given
# \param d_offset distance between the target position and the landing position
def func_s(inParams, d_offset):
    if ((math.fabs((d_offset / inParams.p_target)) < 2.0e-2)) :
        return "The target was hit."
    elif ((d_offset < 0)) :
        return "The projectile fell short."
    else :
        return "The projectile went long."

