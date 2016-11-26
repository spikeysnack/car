/* chunker.c */

/** chunker takes an input file and makes a new file from a chunk of it.
 *  use:  chunker <inputfile> <outputfile> offset  size 
 * 
 *  offset is a long integer and is the byte offset to start chunking.
 *  size   is a size_t long  integer and is the bytecount to stop chunking
 *  and output the bytes to the outputfile. 
 *
 *  compile:       CC -o chunker chunker.c 
 *  debug compile: CC -ggdb -O0 -o chunker chunker.c 
 */


#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <unistd.h>
#include <string.h>
#include <sys/stat.h>
#include <errno.h>
#include <error.h>



int file_exists (char *f);
int chunk( char* fin, char* fout, long seek, size_t size );
int write_file(char* fout , const unsigned char* buf, size_t size);

/* chunk a file into other files */


int file_exists (char *f)
{
  struct stat   buffer;   
  return (stat (f, &buffer) == 0);
}


int chunk( char* fin, char* fout, long seek, size_t size )
{
  FILE *file = NULL;
  
  unsigned char*  buffer = NULL;  // array of bytes, not pointers-to-bytes
  
  size_t bytesRead = 0;
  
  errno = 0;
  buffer=calloc( size , sizeof(unsigned char)); 
  if (errno)  goto err;

  file = fopen( fin, "rb");
  if (errno) goto err;

  fseek(file, seek, SEEK_SET);
  if (errno) goto err;

  if (file != NULL) 
    {
      bytesRead = fread(buffer, sizeof( unsigned char ) , size, file);
#ifdef DEBUG
      fprintf( stderr, "bytes read:\t%lu\n" , bytesRead);
#endif
      
    }
  if (errno) goto err;
  

  errno =  write_file( fout, (const void*)buffer, bytesRead );
  
 err:
  free(buffer);
  fclose(file);

#ifdef DEBUG
  frpintf(stderr, "chunk:\t %s %s %lu %zu\n" , fin, fout , seek, size);  
  perror(strerror(errno));
#endif

  return errno;
}



int write_file(char* fout , const unsigned char* buf, size_t size)
{
  FILE *file = NULL; 
  size_t byteswritten = 0;
  struct stat statp = {0};

  /* struct stat { */
  /*   dev_t     st_dev;     /\* ID of device containing file *\/ */
  /*   ino_t     st_ino;     /\* inode number *\/ */
  /*   mode_t    st_mode;    /\* protection *\/ */
  /*   nlink_t   st_nlink;   /\* number of hard links *\/ */
  /*   uid_t     st_uid;     /\* user ID of owner *\/ */
  /*   gid_t     st_gid;     /\* group ID of owner *\/ */
  /*   dev_t     st_rdev;    /\* device ID (if special file) *\/ */
  /*   off_t     st_size;    /\* total size, in bytes *\/ */
  /*   blksize_t st_blksize; /\* blocksize for filesystem I/O *\/ */
  /*   blkcnt_t  st_blocks;  /\* number of 512B blocks allocated *\/ */
  /*   time_t    st_atime;   /\* time of last access *\/ */
  /*   time_t    st_mtime;   /\* time of last modification *\/ */
  /*   time_t    st_ctime;   /\* time of last status change *\/ */
  /* }; */

  errno = 0;

  /* if file exists rename to file.old */
  if( file_exists(fout) )
    { 
      // file exists
      errno=0;
      stat( fout, &statp);
      
      char* newname = (char*)calloc(strlen(fout) + 4 , sizeof(char));      
      if (errno)  goto err;
      errno = 0;
      newname = strncat( newname, fout, strlen(fout) );  
      newname = strncat( newname, ".old", 4 );  
      rename  (fout, newname );
      if (errno)  goto err;
      free(newname);
    } 

  if ( errno == ENOENT ) {
#ifdef DEBUG
    fprintf( stderr, "NOT Exists\n" );
#endif
  errno=0;
  }

  file=fopen( fout, "wb" );
  if (errno) goto err;
  
  if (file != NULL)    
    {
      errno = 0;

      byteswritten = fwrite(buf, sizeof(unsigned char), size, file);
#ifdef DEBUG
      fprintf( stderr, "bytes written:\t%lu\n" , byteswritten);
#endif
      if (errno) goto err;
      
      if ( statp.st_mode )
	{
	  chmod(fout, statp.st_mode );
	}	  
      else
	{
	  chmod(fout, (mode_t)00644 );	  
	}
    }//if file
  
 err :
  fclose(file);
#ifdef DEBUG
  frpintf(stderr, "write_file:\t %s  %zu\n" , fout, size);  
  perror(strerror(errno));
#endif
 
  return errno;
}





int main( int argc, char** argv, char** env)
{

  char *fin   = NULL; 
  char *fout  = NULL; 
  char*fp     = NULL;
  char *pos   = NULL;
  long seek   = 0;
  size_t size = 0;

  errno=0;

  if ( argc < 4)
    {

      fprintf( stderr, "chunker usage:\t infile(str)  outfile(str)  offset(int)  size (int)\n"   );
      fflush(stderr);
      errno=EINVAL; 
      goto err;
    }


  if ( argv[1] )  fin = strndup( argv[1], strlen( argv[1]));
  else { errno=EINVAL; goto err;}


  if (argv[2]) 
    {
      fout = strndup( argv[2], strlen( argv[2]) );
      fp = fout; /*save for freeing*/
      pos = strrchr(fout, '/');

      if(pos != NULL) fout = pos+1;

#ifdef DEBUG
      fprintf( stderr, "baseneme: (%s)", fout);
#endif
    }
  else { errno=EINVAL; goto err;}


  sscanf( argv[3] ,"%ld" , &seek );
  if (errno) goto err;    

  sscanf( argv[4] ,"%zu" , &size);
  if (errno) goto err;    
#ifdef DEBUG
  fprintf( stderr, "seek:\t%ld\tsize:\t%zu\n", seek, size);
#endif
  errno = chunk( fin, fout, seek, size);  

  if (errno) goto err;    
  

 done:

  free(fp);
  free(fin);

  return 0;

 err:
#ifdef DEBUG
  perror(strerror(errno));
#endif

  return -1;
} //main



