import * as types from '../mutation_types';
import { findIndexOfFile } from '../utils';

export default {
  [types.SET_FILE_ACTIVE](state, { file, active }) {
    Object.assign(file, {
      active,
    });
  },
  [types.TOGGLE_FILE_OPEN](state, file) {
    Object.assign(file, {
      opened: !file.opened,
    });

    if (file.opened) {
      state.openFiles.push(file);
    } else {
      state.openFiles.splice(findIndexOfFile(state.openFiles, file), 1);
    }
  },
  [types.SET_FILE_DATA](state, { data, file }) {
    Object.assign(file, {
      blamePath: data.blame_path,
      commitsPath: data.commits_path,
      permalink: data.permalink,
      rawPath: data.raw_path,
      binary: data.binary,
      html: data.html,
    });
  },
  [types.SET_FILE_RAW_DATA](state, { file, raw }) {
    Object.assign(file, {
      raw,
    });
  },
  [types.UPDATE_FILE_CONTENT](state, { file, content }) {
    const changed = content !== file.raw;

    Object.assign(file, {
      content,
      changed,
    });
  },
  [types.DISCARD_FILE_CHANGES](state, file) {
    Object.assign(file, {
      content: '',
      changed: false,
    });
  },
};
