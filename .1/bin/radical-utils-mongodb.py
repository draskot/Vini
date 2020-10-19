#!/data/mgltools/MakeInstallers/python2.7/bin/python


import os
import sys
import pprint
import radical.utils as ru


_DEFAULT_MODE  = 'list'
_DEFAULT_DBURL = 'mongodb://localhost:27017/'
_DEFAULT_DBURL = 'mongodb://ec2-184-72-89-141.compute-1.amazonaws.com:27017/'

if  'RADICAL_PILOT_DBURL' in os.environ :
    _DEFAULT_DBURL = os.environ['RADICAL_PILOT_DBURL']


# ------------------------------------------------------------------------------
#
def usage (msg=None, noexit=False) :

    if  msg :
        print "\n\t%s\n" % msg

    print """

      usage   : %s -m mode [-d url]
      example : %s mongodb://localhost/synapse_profiles/profiles/

      The URL is interpreted as:
          [schema]://[host]:[port]/[database]/[collection]/[document_id]

      modes are:

        help:   show this message
        tree:   show a tree of the hierarchy, but only  document IDs, no content
        dump:   show a tree of the hierarchy, including document contents
        list:   list entries in the subtree, but do not traverse
        remove: remove the specified subtree

      The default command is 'tree'.  
      The default MongoDB is """ + "'%s'\n\n" % _DEFAULT_DBURL

    if  msg :
        sys.exit (1)

    if  not noexit :
        sys.exit (0)


# ------------------------------------------------------------------------------
#
def dump (url, mode) :
    """
    Connect to mongodb at the given location, and traverse the data bases
    """

    mongo, db, dbname, cname, pname = ru.mongodb_connect (url, _DEFAULT_DBURL)

    print dbname
 
    if  dbname : dbnames = [dbname]
    else       : dbnames = mongo.database_names ()

    for name in dbnames :

        if  mode == 'list' and not dbname :
            print " +-- db   %s" % name

        elif  mode == 'remove' :
            
            if (not dbname) or (name == dbname) :
                try :
                    mongo.drop_database (name)
                    print "  removed database %s" % name
                except :
                    pass # ignore system tables

        else :
            handle_db (mongo, mode, name, cname, pname)

    mongo.disconnect ()


# ------------------------------------------------------------------------------
def handle_db (mongo, mode, dbname, cname, pname) :
    """
    For the given db, traverse collections
    """

    database = mongo[dbname]
    print " +-- db   %s" % dbname


    if  cname : cnames = [cname]
    else      : cnames = database.collection_names ()

    for name in cnames :

        if  mode == 'list' and not cname :
            print " | +-- coll %s" % name

        elif  mode == 'remove' and not pname :
            try :
                database.drop_collection (name)
                print "  removed collection %s" % name
            except :
                pass # ignore errors

        else :
            handle_coll (database, mode, name, pname)



# ------------------------------------------------------------------------------
def handle_coll (database, mode, cname, pname) :
    """
    For a given collection, traverse all documents
    """

    if 'indexes' in cname :
        return

    collection = database[cname]
    print " | +-- coll %s" % cname

    docs = collection.find ()

    for doc in docs :

        name = doc['_id']

        if  mode == 'list' and not pname :
            print " | | +-- doc  %s" % name

        elif  mode == 'remove' :
            if (not pname) or (str(name)==str(pname)) :
                try :
                    collection.remove (name)
                    print "  removed document %s" % name
                except Exception as e:
                    pass # ignore errors

        else :
            if (not pname) or (str(name)==str(pname)) :
                handle_doc (collection, mode, doc)


# ------------------------------------------------------------------------------
def handle_doc (collection, mode, doc) :
    """
    And, surprise, for a given document, show it according to 'mode'
    """

    name = doc['_id']

    if  mode == 'list' :

        for key in doc :
            print " | | | +-- %s" % (key)

    elif  mode == 'tree' :
        print " | | +-- doc  %s" % (name)
        for key in doc :
            print " | | | +-- %s" % (key)

    elif  mode == 'dump' :
        print " | | +-- doc  %s" % (name)
        for key in doc :
            txt_in  = pprint.pformat (doc[key])
            txt_out = ""
            lnum    = 1
            for line in txt_in.split ('\n') :
                if  lnum != 1 :
                    txt_out += ' | | | |                '
                txt_out += line
                txt_out += '\n'
                lnum    += 1

            print " | | | +-- %-10s : %s" % (key, txt_out[:-1]) # remove last \n


# ------------------------------------------------------------------------------
#
if __name__ == '__main__' :

    import optparse
    parser = optparse.OptionParser (add_help_option=False)

    parser.add_option('-m', '--mode',    dest='mode')
    parser.add_option('-d', '--dburl',   dest='dburl')
    parser.add_option('-h', '--help',    dest='help', action="store_true")

    options, args = parser.parse_args ()

    if  args         : usage ("Too many arguments (%s)" % args) 
    if  options.help : usage ()

    mode    = options.mode 
    dburl   = options.dburl

    if not mode  : mode  = _DEFAULT_MODE
    if not dburl : dburl = _DEFAULT_DBURL

    print "modes   : %s" % mode
    print "db url  : %s" % dburl

    for m in mode.split (',') :

        if  m not in ['list', 'dump', 'tree', 'remove', 'help'] : 
            usage ("Unsupported mode '%s'" % m)

        elif m == 'tree'   : dump  (dburl, m) 
        elif m == 'dump'   : dump  (dburl, m) 
        elif m == 'list'   : dump  (dburl, m) 
        elif m == 'remove' : dump  (dburl, m) 
        elif m == 'help'   : usage (noexit=True)
        else               : usage ("unknown mode '%s'" % mode)


# ------------------------------------------------------------------------------

