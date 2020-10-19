################################################################################
##
## This library is free software; you can redistribute it and/or
## modify it under the terms of the GNU Lesser General Public
## License as published by the Free Software Foundation; either
## version 2.1 of the License, or (at your option) any later version.
## 
## This library is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
## Lesser General Public License for more details.
## 
## You should have received a copy of the GNU Lesser General Public
## License along with this library; if not, write to the Free Software
## Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301 USA
##
## (C) Copyrights Dr. Michel F. Sanner and TSRI 2016
##
################################################################################

#############################################################################
#
# Author: Michel F. SANNER
#
# Copyright: M. Sanner and TSRI 2016
#
#########################################################################
#
# $Header: /opt/cvs/AutoSite/scoreClusters.py,v 1.3 2017/04/13 00:52:43 annao Exp $
#
# $Id: scoreClusters.py,v 1.3 2017/04/13 00:52:43 annao Exp $
#
import numpy

from math import sqrt

from AutoSite.fillBuriedness import Buriedness

def scoreClusters(rec, dcl, gc):
    coords = rec._ag.getCoords()
    radii = rec._ag.getRadii()
    clusters = []
    clProp = []
    for clinds in dcl._clusters:
        cli = gc._indices[clinds]
        clc = gc._coords[clinds]
        clp = gc._potential[clinds]
        cla = gc._atype[clinds]
        if len(cli)==1:
            metric = Rg = fburied = 0.
        else:
            #import pdb;pdb.set_trace()
            dmetric = Buriedness(clc, cla, coords.tolist(), radii )
            cx,cy,cz = numpy.mean(clc,axis=0)
            dst2 = 0.0
            for px,py,pz in clc:
                dst2 += (px-cx)*(px-cx)+(py-cy)*(py-cy)+(pz-cz)*(pz-cz)
            complen = len(clc)
            Rg2 = (dst2/complen)
            Rg = sqrt(Rg2)
            fburied = dmetric.NumericalBurriedness(spacing=1.0)
            metric = (len(clc)*fburied*fburied)/Rg
        clusters.append( [cli, clc, clp, cla, metric] )
        clProp.append([numpy.sum(clp), len(clc), numpy.sum(clp)/len(clc), Rg, fburied, metric])
    return clusters, clProp

