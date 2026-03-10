install_data(
    '48x48' / 'gftp.png',
    rename: 'gftp.png',
    install_dir: install_dir_base / get_option('datadir') / 'gftp'
)

# if a size is missing, generate one by scaling any existing
# icon rather than failing.  this makes the build robust even if we only
# ship a single size (typically 48×48) while we work on real artwork.
# prefer ImageMagick's `convert` or fall back to `sips` on macOS; if
# neither is available we'll just copy the closest size.
convert_prog = find_program('convert', required: false)
sips_prog = find_program('sips', required: false)

# helper for filesystem checks
fs = import('fs')

# find the largest source icon that actually exists in the tree; this
# gives the best results when scaling up or down.
sizes = ['48x48','32x32','24x24','22x22','16x16']
source_icon = ''
foreach s : sizes
    if fs.exists(s + '/gftp.png')
        source_icon = s + '/gftp.png'
        break
    endif
endforeach
if source_icon == ''
    error('no source gftp.png icon found in any size, please add at least one')
endif

foreach dir : ['16x16','22x22','24x24','32x32','48x48']
    icon_file = dir / 'gftp.png'
    if not fs.exists(icon_file)
        warning('icon ' + icon_file + ' missing; generating by rescaling ' + source_icon)
        # perform the scaling during configuration rather than at build time
        if convert_prog.found()
            run_command(convert_prog, source_icon,
                        '-resize', dir + 'x' + dir,
                        icon_file)
        elif sips_prog.found()
            run_command(sips_prog, '-z', dir, dir,
                        source_icon, '--out', icon_file)
        else
            run_command('cp', source_icon, icon_file)
        endif
    endif
    install_data(
        icon_file,
        install_dir: install_dir_base / get_option('datadir') / 'icons' / 'hicolor' / dir / 'apps'
    )
endforeach
install_data(
    'scalable' / 'gftp.svg',
    install_dir: install_dir_base / get_option('datadir') / 'icons' / 'hicolor' / 'scalable' / 'apps'
)